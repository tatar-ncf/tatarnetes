package freeze

import (
	"bufio"
	"bytes"
	"fmt"
	"io/fs"
	"path"
	"strings"
)

// Catalog holds the messages of locale/*.po, the same catalog the shell
// tools read through lib/catalog.sh: language -> key -> format.
type Catalog map[string]map[string]string

// LoadCatalog reads every locale/<lang>.po of fsys.
func LoadCatalog(fsys fs.FS) (Catalog, error) {
	files, err := fs.Glob(fsys, "locale/*.po")
	if err != nil {
		return nil, err
	}
	c := Catalog{}
	for _, f := range files {
		raw, err := fs.ReadFile(fsys, f)
		if err != nil {
			return nil, err
		}
		msgs, err := parsePO(raw)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", f, err)
		}
		c[strings.TrimSuffix(path.Base(f), ".po")] = msgs
	}
	if len(c) == 0 {
		return nil, fmt.Errorf("no locale/*.po")
	}
	return c, nil
}

// parsePO reads single-line msgid/msgstr pairs, as scripts/build-catalog.sh
// does: entries with an empty msgstr are left out.
func parsePO(raw []byte) (map[string]string, error) {
	out := map[string]string{}
	var key string
	sc := bufio.NewScanner(bytes.NewReader(raw))
	for n := 1; sc.Scan(); n++ {
		line := strings.TrimSpace(sc.Text())
		switch {
		case strings.HasPrefix(line, "msgid "):
			v, err := unquote(strings.TrimPrefix(line, "msgid "))
			if err != nil {
				return nil, fmt.Errorf("line %d: %w", n, err)
			}
			key = v
		case strings.HasPrefix(line, "msgstr "):
			v, err := unquote(strings.TrimPrefix(line, "msgstr "))
			if err != nil {
				return nil, fmt.Errorf("line %d: %w", n, err)
			}
			if key != "" && v != "" {
				out[key] = v
			}
			key = ""
		}
	}
	return out, sc.Err()
}

func unquote(s string) (string, error) {
	if len(s) < 2 || s[0] != '"' || s[len(s)-1] != '"' {
		return "", fmt.Errorf("not a quoted string: %s", s)
	}
	s = s[1 : len(s)-1]
	s = strings.ReplaceAll(s, `\"`, `"`)
	return strings.ReplaceAll(s, `\\`, `\`), nil
}

// T formats a message in lang, falling back to the key itself.
func (c Catalog) T(lang, key string, args ...any) string {
	f, ok := c[lang][key]
	if !ok {
		return key
	}
	return fmt.Sprintf(f, args...)
}

// Both is the message in Tatar, then in English: the cluster's users read
// either.
func (c Catalog) Both(key string, args func(lang string) []any) string {
	return c.T("tt", key, args("tt")...) + " / " + c.T("en", key, args("en")...)
}
