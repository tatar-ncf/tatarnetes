// Package tatarnetes carries the data the shell and the Go services share:
// the gettext catalogs in locale/ and the verified holidays in data/.
package tatarnetes

import "embed"

// Assets holds locale/*.po and data/holidays.tt as the repository has them.
//
//go:embed locale/*.po data/holidays.tt
var Assets embed.FS
