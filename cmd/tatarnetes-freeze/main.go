// tatarnetes-freeze is the change freeze of Tatarnetes: a validating
// admission webhook that denies changes in namespaces labelled
// tatar-ncf.github.io/change-freeze on the verified holidays of
// data/holidays.tt, with its messages from locale/*.po.
package main

import (
	"crypto/tls"
	"flag"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
	_ "time/tzdata" // the image has no zoneinfo

	"github.com/tatar-ncf/tatarnetes"
	"github.com/tatar-ncf/tatarnetes/freeze"
)

func main() {
	listen := flag.String("listen", ":8443", "address to serve on")
	certFile := flag.String("tls-cert-file", "/tls/tls.crt", "serving certificate, reread when it changes")
	keyFile := flag.String("tls-key-file", "/tls/tls.key", "its key")
	zone := flag.String("timezone", "Europe/Moscow", "the time zone whose date decides the holiday (Kazan's by default)")
	mode := flag.String("mode", freeze.ModeEnforce, "enforce, or warn to only warn in every namespace")
	holidays := flag.String("holidays", "", "a holidays.tt to use instead of the built-in data/holidays.tt")
	exemptUsers := flag.String("exempt-users", "system:kube-controller-manager,system:kube-scheduler,system:node:*,system:serviceaccount:kube-system:*,system:serviceaccount:keda:keda-operator",
		"users never frozen, comma-separated; a trailing * matches a prefix")
	exemptGroups := flag.String("exempt-groups", "system:nodes", "groups never frozen, comma-separated")
	skip := flag.String("skip-resources", "events,leases", "resources never frozen, comma-separated")
	today := flag.String("today", os.Getenv("TATARNETES_FREEZE_TODAY"),
		"pretend the date is YYYY-MM-DD in --timezone, for tests; empty: the real date ($TATARNETES_FREEZE_TODAY)")
	flag.Parse()

	if *mode != freeze.ModeEnforce && *mode != freeze.ModeWarn {
		log.Fatalf("--mode %q: want enforce or warn", *mode)
	}
	loc, err := time.LoadLocation(*zone)
	if err != nil {
		log.Fatalf("--timezone: %v", err)
	}
	raw, err := tatarnetes.Assets.ReadFile("data/holidays.tt")
	if *holidays != "" {
		raw, err = os.ReadFile(*holidays)
	}
	if err != nil {
		log.Fatalf("holidays: %v", err)
	}
	cal, err := freeze.ParseHolidays(raw)
	if err != nil {
		log.Fatalf("holidays: %v", err)
	}
	cat, err := freeze.LoadCatalog(tatarnetes.Assets)
	if err != nil {
		log.Fatalf("catalog: %v", err)
	}
	now, err := freeze.FixedDay(*today, loc)
	if err != nil {
		log.Fatalf("--today: %v", err)
	}
	if *today != "" {
		log.Printf("pretending today is %s", *today)
	}
	f := &freeze.Freeze{Calendar: cal, Catalog: cat, Location: loc, Now: now, Mode: *mode,
		ExemptUsers: list(*exemptUsers), ExemptGroups: list(*exemptGroups), SkipResources: list(*skip)}
	if parents, err := freeze.NewInCluster(); err == nil {
		f.Parents = parents
	} else {
		log.Printf("break-glass on scale will not work: %v", err)
	}
	log.Printf("change freeze: %d holidays, %s, mode %s", len(cal), loc, *mode)

	mux := http.NewServeMux()
	mux.Handle("/validate/", f)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("ok\n")) })
	certs := &reloader{cert: *certFile, key: *keyFile}
	srv := &http.Server{Addr: *listen, Handler: mux, ReadHeaderTimeout: 10 * time.Second,
		TLSConfig: &tls.Config{MinVersion: tls.VersionTLS12, GetCertificate: certs.get}}
	log.Fatal(srv.ListenAndServeTLS("", ""))
}

func list(s string) []string {
	var out []string
	for _, v := range strings.Split(s, ",") {
		if v = strings.TrimSpace(v); v != "" {
			out = append(out, v)
		}
	}
	return out
}

// reloader serves the certificate on disk, read again when its file changes,
// so a renewed certificate needs no restart.
type reloader struct {
	cert, key string
	mu        sync.Mutex
	mod       time.Time
	current   *tls.Certificate
}

func (r *reloader) get(*tls.ClientHelloInfo) (*tls.Certificate, error) {
	st, err := os.Stat(r.cert)
	r.mu.Lock()
	defer r.mu.Unlock()
	if err == nil && (r.current == nil || st.ModTime() != r.mod) {
		c, lerr := tls.LoadX509KeyPair(r.cert, r.key)
		if lerr == nil {
			r.current, r.mod = &c, st.ModTime()
		} else if r.current == nil {
			return nil, lerr
		}
	}
	if r.current == nil {
		return nil, err
	}
	return r.current, nil
}
