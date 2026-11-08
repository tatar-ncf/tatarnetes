// Package freeze is a change freeze for holidays: an admission webhook that
// denies changes in the namespaces that ask for it on the verified holidays
// of data/holidays.tt (Uraza, Qorban, Sabantuy), in Tatar and English from
// the project's own catalog.
package freeze

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"slices"
	"strings"
	"time"
)

const (
	// NamespaceLabel opts a namespace in: "enforce" denies changes on a
	// holiday, "warn" lets them through with a warning.
	NamespaceLabel = "tatar-ncf.github.io/change-freeze"
	// BreakGlassAnnotation on the object, with the reason as its value, lets
	// a change through a freeze; the API server returns the warning and the
	// webhook logs it.
	BreakGlassAnnotation = "tatar-ncf.github.io/break-glass"

	ModeEnforce = "enforce"
	ModeWarn    = "warn"
)

// Freeze decides on admission requests.
type Freeze struct {
	Calendar Calendar
	Catalog  Catalog
	Location *time.Location
	Now      func() time.Time
	// Mode "warn" turns every namespace's freeze into warnings: a dry run
	// of the freeze for the whole cluster.
	Mode string
	// ExemptUsers and ExemptGroups are never frozen: the cluster's own
	// controllers must keep pods, endpoints and leases going on a holiday.
	// A trailing "*" matches a prefix.
	ExemptUsers  []string
	ExemptGroups []string
	// SkipResources are never frozen (events, leases).
	SkipResources []string
	// Parents reads the object a scale request is for, to find its
	// break-glass annotation; nil: scaling is frozen with no way through.
	Parents Parents
}

// Review is the part of admission.k8s.io/v1 AdmissionReview the webhook uses.
type Review struct {
	APIVersion string    `json:"apiVersion"`
	Kind       string    `json:"kind"`
	Request    *Request  `json:"request,omitempty"`
	Response   *Response `json:"response,omitempty"`
}

type Request struct {
	UID         string                                    `json:"uid"`
	Kind        struct{ Group, Version, Kind string }     `json:"kind"`
	Resource    struct{ Group, Version, Resource string } `json:"resource"`
	SubResource string                                    `json:"subResource,omitempty"`
	Namespace   string                                    `json:"namespace,omitempty"`
	Name        string                                    `json:"name,omitempty"`
	Operation   string                                    `json:"operation"`
	UserInfo    UserInfo                                  `json:"userInfo"`
	Object      json.RawMessage                           `json:"object,omitempty"`
	OldObject   json.RawMessage                           `json:"oldObject,omitempty"`
	DryRun      *bool                                     `json:"dryRun,omitempty"`
}

type UserInfo struct {
	Username string   `json:"username"`
	Groups   []string `json:"groups,omitempty"`
}

type Response struct {
	UID      string   `json:"uid"`
	Allowed  bool     `json:"allowed"`
	Result   *Status  `json:"status,omitempty"`
	Warnings []string `json:"warnings,omitempty"`
}

type Status struct {
	Code    int32  `json:"code,omitempty"`
	Reason  string `json:"reason,omitempty"`
	Message string `json:"message,omitempty"`
}

// Decide answers one request; mode is the namespace's (from the webhook
// path), which the global Mode may soften to warn.
func (f *Freeze) Decide(req *Request, mode string) *Response {
	allow := &Response{UID: req.UID, Allowed: true}
	key, holiday := f.Calendar.On(f.Now(), f.Location)
	if !holiday {
		return allow
	}
	switch req.Operation {
	case "CREATE", "UPDATE", "DELETE":
	default:
		return allow
	}
	scale := isScale(req)
	if (req.SubResource != "" && !scale) || slices.Contains(f.SkipResources, req.Resource.Resource) || f.exempt(req.UserInfo) {
		return allow
	}
	day := func(lang string) string { return f.Catalog.T(lang, HolidayName(key)) }
	what := req.Resource.Resource
	if req.SubResource != "" {
		what += "/" + req.SubResource
	}
	if reason := f.breakGlass(req, scale); reason != "" {
		msg := f.Catalog.Both("freeze.breakglass", func(l string) []any { return []any{day(l), BreakGlassAnnotation, reason} })
		log.Printf("break-glass: %s %s %s/%s by %s: %s", req.Operation, what, req.Namespace, req.Name, req.UserInfo.Username, reason)
		allow.Warnings = []string{msg}
		return allow
	}
	if mode != ModeEnforce || f.Mode == ModeWarn {
		allow.Warnings = []string{f.Catalog.Both("freeze.warn", func(l string) []any { return []any{day(l), req.Namespace} })}
		log.Printf("warn: %s %s %s/%s by %s", req.Operation, what, req.Namespace, req.Name, req.UserInfo.Username)
		return allow
	}
	log.Printf("deny: %s %s %s/%s by %s", req.Operation, what, req.Namespace, req.Name, req.UserInfo.Username)
	return &Response{UID: req.UID, Allowed: false, Result: &Status{
		Code:    http.StatusForbidden,
		Reason:  "Forbidden",
		Message: f.Catalog.Both("freeze.denied", func(l string) []any { return []any{day(l), req.Namespace, BreakGlassAnnotation} }),
	}}
}

func isScale(req *Request) bool {
	return req.SubResource == "scale" && slices.Contains(Scalable, req.Resource.Group+"/"+req.Resource.Resource)
}

// breakGlass is the reason in the break-glass annotation: on the object, on
// the old object of a delete, or on the parent of a scale request.
func (f *Freeze) breakGlass(req *Request, scale bool) string {
	if !scale {
		obj := req.Object
		if req.Operation == "DELETE" {
			obj = req.OldObject
		}
		return annotation(obj, BreakGlassAnnotation)
	}
	if f.Parents == nil {
		log.Printf("scale %s/%s: no API access to read break-glass from the parent", req.Namespace, req.Name)
		return ""
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	a, err := f.Parents.Annotations(ctx, req)
	if err != nil {
		log.Printf("scale %s/%s: reading the parent: %v", req.Namespace, req.Name, err)
		return ""
	}
	return strings.TrimSpace(a[BreakGlassAnnotation])
}

func (f *Freeze) exempt(u UserInfo) bool {
	for _, p := range f.ExemptUsers {
		if match(p, u.Username) {
			return true
		}
	}
	for _, g := range u.Groups {
		for _, p := range f.ExemptGroups {
			if match(p, g) {
				return true
			}
		}
	}
	return false
}

func match(pattern, s string) bool {
	if prefix, ok := strings.CutSuffix(pattern, "*"); ok {
		return strings.HasPrefix(s, prefix)
	}
	return pattern == s
}

func annotation(raw json.RawMessage, key string) string {
	var o struct {
		Metadata struct {
			Annotations map[string]string `json:"annotations"`
		} `json:"metadata"`
	}
	if len(raw) == 0 || json.Unmarshal(raw, &o) != nil {
		return ""
	}
	return strings.TrimSpace(o.Metadata.Annotations[key])
}

// maxReview bounds a request body: objects stored in the cluster are at most
// a few megabytes, an object and its old version twice that.
const maxReview = 16 << 20

// ServeHTTP answers AdmissionReviews at /validate/enforce and /validate/warn.
func (f *Freeze) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	mode := strings.TrimPrefix(r.URL.Path, "/validate/")
	if mode != ModeEnforce && mode != ModeWarn {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "POST an AdmissionReview", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, maxReview+1))
	if err != nil || len(body) > maxReview {
		http.Error(w, "unreadable or too large", http.StatusBadRequest)
		return
	}
	var review Review
	if err := json.Unmarshal(body, &review); err != nil || review.Request == nil {
		http.Error(w, fmt.Sprintf("not an AdmissionReview: %v", err), http.StatusBadRequest)
		return
	}
	out := Review{APIVersion: "admission.k8s.io/v1", Kind: "AdmissionReview", Response: f.Decide(review.Request, mode)}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(out)
}
