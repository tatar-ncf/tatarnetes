package freeze

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type fakeParents struct {
	annotations map[string]string
	err         error
	asked       *Request
}

func (p *fakeParents) Annotations(_ context.Context, r *Request) (map[string]string, error) {
	p.asked = r
	return p.annotations, p.err
}

func scaleReq(resource string) *Request {
	r := req("UPDATE")
	r.Resource.Group, r.Resource.Version, r.Resource.Resource = "apps", "v1", resource
	r.SubResource = "scale"
	r.Object = []byte(`{"apiVersion":"autoscaling/v1","kind":"Scale","metadata":{"name":"web"},"spec":{"replicas":3}}`)
	return r
}

func TestScaleIsFrozen(t *testing.T) {
	for _, res := range []string{"deployments", "statefulsets", "replicasets"} {
		f := newFreeze(t, sabantuy)
		f.Parents = &fakeParents{}
		if resp := f.Decide(scaleReq(res), ModeEnforce); resp.Allowed {
			t.Errorf("%s/scale by a human was allowed", res)
		}
		if resp := f.Decide(scaleReq(res), ModeWarn); !resp.Allowed || len(resp.Warnings) != 1 {
			t.Errorf("%s/scale in a warn namespace: %+v", res, resp)
		}
	}
	// Other subresources stay untouched.
	r := scaleReq("deployments")
	r.SubResource = "status"
	if resp := newFreeze(t, sabantuy).Decide(r, ModeEnforce); !resp.Allowed {
		t.Error("deployments/status was frozen")
	}
}

func TestScaleByControllers(t *testing.T) {
	f := newFreeze(t, sabantuy)
	f.ExemptUsers = append(f.ExemptUsers, "system:serviceaccount:keda:keda-operator")
	p := &fakeParents{}
	f.Parents = p
	for _, user := range []string{
		"system:serviceaccount:kube-system:horizontal-pod-autoscaler",
		"system:kube-controller-manager",
		"system:serviceaccount:keda:keda-operator",
	} {
		r := scaleReq("deployments")
		r.UserInfo.Username = user
		if resp := f.Decide(r, ModeEnforce); !resp.Allowed || len(resp.Warnings) != 0 {
			t.Errorf("%s: %+v", user, resp)
		}
	}
	if p.asked != nil {
		t.Error("the parent was read for an exempt controller")
	}
}

func TestScaleBreakGlassOnTheParent(t *testing.T) {
	f := newFreeze(t, sabantuy)
	p := &fakeParents{annotations: map[string]string{BreakGlassAnnotation: "INC-42 payment outage"}}
	f.Parents = p
	resp := f.Decide(scaleReq("statefulsets"), ModeEnforce)
	if !resp.Allowed || len(resp.Warnings) != 1 || !strings.Contains(resp.Warnings[0], "INC-42") {
		t.Errorf("break-glass on the parent: %+v", resp)
	}
	if p.asked == nil || p.asked.Resource.Resource != "statefulsets" || p.asked.Name != "web" {
		t.Errorf("asked for %+v", p.asked)
	}
	// An unreadable parent, or none to read: no way through.
	f.Parents = &fakeParents{err: errors.New("forbidden")}
	if resp := f.Decide(scaleReq("deployments"), ModeEnforce); resp.Allowed {
		t.Error("an unreadable parent let the scale through")
	}
	f.Parents = nil
	if resp := f.Decide(scaleReq("deployments"), ModeEnforce); resp.Allowed {
		t.Error("no API access let the scale through")
	}
}

func TestInClusterReadsTheParent(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer tok" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		switch r.URL.Path {
		case "/apis/apps/v1/namespaces/shop/deployments/web":
			_, _ = w.Write([]byte(`{"metadata":{"name":"web","annotations":{"` + BreakGlassAnnotation + `":"INC-7"}}}`))
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()
	tok := filepath.Join(t.TempDir(), "token")
	if err := os.WriteFile(tok, []byte("tok\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	c := &InCluster{Server: srv.URL, TokenFile: tok, Client: srv.Client()}
	a, err := c.Annotations(context.Background(), scaleReq("deployments"))
	if err != nil || a[BreakGlassAnnotation] != "INC-7" {
		t.Errorf("annotations %v, %v", a, err)
	}
	if _, err := c.Annotations(context.Background(), scaleReq("statefulsets")); err == nil {
		t.Error("a missing parent was no error")
	}
}
