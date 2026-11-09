package freeze

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/tatar-ncf/tatarnetes"
)

var kazan = func() *time.Location {
	l, err := time.LoadLocation("Europe/Moscow")
	if err != nil {
		panic(err)
	}
	return l
}()

// newFreeze reads the repository's own holidays and catalog, as the binary does.
func newFreeze(t *testing.T, now time.Time) *Freeze {
	t.Helper()
	raw, err := tatarnetes.Assets.ReadFile("data/holidays.tt")
	if err != nil {
		t.Fatal(err)
	}
	cal, err := ParseHolidays(raw)
	if err != nil {
		t.Fatal(err)
	}
	cat, err := LoadCatalog(tatarnetes.Assets)
	if err != nil {
		t.Fatal(err)
	}
	return &Freeze{Calendar: cal, Catalog: cat, Location: kazan, Now: func() time.Time { return now },
		ExemptUsers: []string{"system:serviceaccount:kube-system:*", "system:kube-controller-manager"}, ExemptGroups: []string{"system:nodes"},
		SkipResources: []string{"events", "leases"}}
}

var (
	sabantuy  = time.Date(2026, 6, 20, 10, 0, 0, 0, kazan)
	ordinary  = time.Date(2026, 6, 19, 10, 0, 0, 0, kazan)
	sabantuy7 = time.Date(2027, 6, 20, 10, 0, 0, 0, kazan) // not verified
)

func req(op string) *Request {
	r := &Request{UID: "u1", Operation: op, Namespace: "shop", Name: "web", UserInfo: UserInfo{Username: "alsu"}}
	r.Resource.Resource = "deployments"
	r.Object = json.RawMessage(`{"metadata":{"name":"web"}}`)
	return r
}

func TestHolidaysAreDated(t *testing.T) {
	cal, err := ParseHolidays([]byte("06-20 festival.sabantuy  # undated\n2026-06-20 festival.sabantuy\n\n# comment\n"))
	if err != nil {
		t.Fatal(err)
	}
	if len(cal) != 1 || cal["2026-06-20"] != "festival.sabantuy" {
		t.Errorf("calendar %v", cal)
	}
	if _, err := ParseHolidays([]byte("2026-06-20\n")); err == nil {
		t.Error("a date without a key was accepted")
	}
}

func TestRepositoryHolidays(t *testing.T) {
	f := newFreeze(t, sabantuy)
	for day, want := range map[string]string{"2026-03-20": "festival.uraza", "2026-05-27": "festival.qorban", "2026-06-20": "festival.sabantuy"} {
		if f.Calendar[day] != want {
			t.Errorf("%s = %q, want %q", day, f.Calendar[day], want)
		}
		if name := f.Catalog.T("tt", HolidayName(want)); strings.HasPrefix(name, "holiday.") {
			t.Errorf("no Tatar name for %s", want)
		}
	}
}

func TestDeniesOnSabantuy(t *testing.T) {
	resp := newFreeze(t, sabantuy).Decide(req("UPDATE"), ModeEnforce)
	if resp.Allowed || resp.Result == nil || resp.Result.Code != 403 {
		t.Fatalf("not denied: %+v", resp)
	}
	for _, want := range []string{"Сабан туе", "Sabantuy", `"shop"`, "«shop»", BreakGlassAnnotation} {
		if !strings.Contains(resp.Result.Message, want) {
			t.Errorf("message %q lacks %q", resp.Result.Message, want)
		}
	}
}

func TestAllows(t *testing.T) {
	for name, c := range map[string]struct {
		now  time.Time
		req  func() *Request
		mode string
	}{
		"an ordinary day": {ordinary, func() *Request { return req("CREATE") }, ModeEnforce},
		"connect":         {sabantuy, func() *Request { return req("CONNECT") }, ModeEnforce},
		"a subresource":   {sabantuy, func() *Request { r := req("UPDATE"); r.SubResource = "status"; return r }, ModeEnforce},
		"events":          {sabantuy, func() *Request { r := req("CREATE"); r.Resource.Resource = "events"; return r }, ModeEnforce},
		"a kube-system controller": {sabantuy, func() *Request {
			r := req("CREATE")
			r.UserInfo.Username = "system:serviceaccount:kube-system:replicaset-controller"
			return r
		}, ModeEnforce},
		"a node": {sabantuy, func() *Request {
			r := req("UPDATE")
			r.UserInfo = UserInfo{Username: "system:node:n1", Groups: []string{"system:nodes"}}
			return r
		}, ModeEnforce},
	} {
		f := newFreeze(t, c.now)
		r := c.req()
		if resp := f.Decide(r, c.mode); !resp.Allowed || len(resp.Warnings) != 0 {
			t.Errorf("%s: %+v", name, resp)
		}
	}
}

// A year without verified dates freezes nothing, and says so to the people
// whose namespaces opted in; the cluster's controllers hear nothing.
func TestUnverifiedYear(t *testing.T) {
	f := newFreeze(t, sabantuy7)
	if f.Calendar.Verified(sabantuy7, kazan) || !f.Calendar.Verified(sabantuy, kazan) {
		t.Fatal("Verified: want 2026 verified and 2027 not")
	}
	resp := f.Decide(req("CREATE"), ModeEnforce)
	if !resp.Allowed || len(resp.Warnings) != 1 {
		t.Fatalf("%+v", resp)
	}
	for _, want := range []string{"Holiday dates for 2027 are not verified yet", "2027 елның"} {
		if !strings.Contains(resp.Warnings[0], want) {
			t.Errorf("warning %q lacks %q", resp.Warnings[0], want)
		}
	}
	controller := req("CREATE")
	controller.UserInfo.Username = "system:kube-controller-manager"
	if resp := f.Decide(controller, ModeEnforce); !resp.Allowed || len(resp.Warnings) != 0 {
		t.Errorf("controller: %+v", resp)
	}
	if resp := newFreeze(t, ordinary).Decide(req("CREATE"), ModeEnforce); len(resp.Warnings) != 0 {
		t.Errorf("verified year: %+v", resp)
	}
}

// The day is Kazan's: half past midnight on Sabantuy is still the 19th in UTC.
func TestTheDayIsKazans(t *testing.T) {
	f := newFreeze(t, time.Date(2026, 6, 19, 21, 30, 0, 0, time.UTC))
	if resp := f.Decide(req("CREATE"), ModeEnforce); resp.Allowed {
		t.Error("00:30 in Kazan on Sabantuy was allowed")
	}
}

func TestWarnModes(t *testing.T) {
	f := newFreeze(t, sabantuy)
	if resp := f.Decide(req("DELETE"), ModeWarn); !resp.Allowed || len(resp.Warnings) != 1 || !strings.Contains(resp.Warnings[0], "Sabantuy") {
		t.Errorf("namespace in warn mode: %+v", resp)
	}
	f.Mode = ModeWarn
	if resp := f.Decide(req("CREATE"), ModeEnforce); !resp.Allowed || len(resp.Warnings) != 1 {
		t.Errorf("cluster-wide warn mode: %+v", resp)
	}
}

func TestBreakGlass(t *testing.T) {
	f := newFreeze(t, sabantuy)
	r := req("UPDATE")
	r.Object = json.RawMessage(`{"metadata":{"annotations":{"` + BreakGlassAnnotation + `":"INC-42 payment outage"}}}`)
	resp := f.Decide(r, ModeEnforce)
	if !resp.Allowed || len(resp.Warnings) != 1 || !strings.Contains(resp.Warnings[0], "INC-42") {
		t.Errorf("break-glass: %+v", resp)
	}
	// A delete carries the annotation on the old object.
	d := req("DELETE")
	d.Object, d.OldObject = nil, r.Object
	if resp := f.Decide(d, ModeEnforce); !resp.Allowed {
		t.Errorf("break-glass delete: %+v", resp)
	}
	// An empty reason is no reason.
	r.Object = json.RawMessage(`{"metadata":{"annotations":{"` + BreakGlassAnnotation + `":" "}}}`)
	if resp := f.Decide(r, ModeEnforce); resp.Allowed {
		t.Error("an empty break-glass annotation let the change through")
	}
}

func TestServeHTTP(t *testing.T) {
	f := newFreeze(t, sabantuy)
	body, _ := json.Marshal(Review{APIVersion: "admission.k8s.io/v1", Kind: "AdmissionReview", Request: req("CREATE")})
	for path, allowed := range map[string]bool{"/validate/enforce": false, "/validate/warn": true} {
		rec := httptest.NewRecorder()
		f.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, path, bytes.NewReader(body)))
		var out Review
		if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil || out.Response == nil {
			t.Fatalf("%s: %d %s", path, rec.Code, rec.Body)
		}
		if out.Response.UID != "u1" || out.Response.Allowed != allowed || out.Kind != "AdmissionReview" {
			t.Errorf("%s: %+v", path, out.Response)
		}
	}
	rec := httptest.NewRecorder()
	f.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/validate/other", bytes.NewReader(body)))
	if rec.Code != http.StatusNotFound {
		t.Errorf("unknown mode: %d", rec.Code)
	}
	rec = httptest.NewRecorder()
	f.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/validate/enforce", strings.NewReader(`{"kind":"AdmissionReview"}`)))
	if rec.Code != http.StatusBadRequest {
		t.Errorf("no request: %d", rec.Code)
	}
}

func TestCatalogMatchesTheShell(t *testing.T) {
	c, err := LoadCatalog(tatarnetes.Assets)
	if err != nil {
		t.Fatal(err)
	}
	// Quotes and escapes come out as lib/catalog.sh has them.
	if got := c.T("en", "err.unknown_verb", "x"); got != `No such command: "x"` {
		t.Errorf("en err.unknown_verb = %q", got)
	}
	if got := c.T("tt", "holiday.sabantuy"); got != "Сабан туе" {
		t.Errorf("tt holiday.sabantuy = %q", got)
	}
}

func TestFixedDay(t *testing.T) {
	now, err := FixedDay("2026-06-20", kazan)
	if err != nil {
		t.Fatal(err)
	}
	f := newFreeze(t, ordinary)
	f.Now = now
	if resp := f.Decide(req("CREATE"), ModeEnforce); resp.Allowed {
		t.Error("a pretended Sabantuy was not frozen")
	}
	if _, err := FixedDay("20.06.2026", kazan); err == nil {
		t.Error("a malformed day was accepted")
	}
}
