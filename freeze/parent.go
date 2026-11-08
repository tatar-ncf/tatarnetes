package freeze

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// Scalable are the resources whose scale subresource is frozen: kubectl
// scale on them is a change like any other. The scale request carries an
// autoscaling/v1 Scale, which has no annotations, so break-glass is read
// from the parent object.
var Scalable = []string{"apps/deployments", "apps/statefulsets", "apps/replicasets"}

// Parents reads the annotations of the object a subresource request is for.
type Parents interface {
	Annotations(ctx context.Context, req *Request) (map[string]string, error)
}

// InCluster reads parents from the API server with the pod's service
// account; the chart grants it get on the Scalable resources only.
type InCluster struct {
	Server    string // https://host:port
	TokenFile string // reread on every call: projected tokens rotate
	Client    *http.Client
}

const saDir = "/var/run/secrets/kubernetes.io/serviceaccount"

// NewInCluster configures an InCluster from the pod's environment.
func NewInCluster() (*InCluster, error) {
	host, port := os.Getenv("KUBERNETES_SERVICE_HOST"), os.Getenv("KUBERNETES_SERVICE_PORT")
	if host == "" || port == "" {
		return nil, fmt.Errorf("not in a cluster: KUBERNETES_SERVICE_HOST/PORT unset")
	}
	ca, err := os.ReadFile(saDir + "/ca.crt")
	if err != nil {
		return nil, err
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(ca) {
		return nil, fmt.Errorf("%s/ca.crt: no certificates", saDir)
	}
	return &InCluster{
		Server:    "https://" + net.JoinHostPort(host, port),
		TokenFile: saDir + "/token",
		Client: &http.Client{Timeout: 3 * time.Second, Transport: &http.Transport{
			TLSClientConfig: &tls.Config{RootCAs: pool, MinVersion: tls.VersionTLS12},
		}},
	}, nil
}

func (c *InCluster) Annotations(ctx context.Context, req *Request) (map[string]string, error) {
	token, err := os.ReadFile(c.TokenFile)
	if err != nil {
		return nil, err
	}
	r := req.Resource
	prefix := "/apis/" + url.PathEscape(r.Group) + "/" + url.PathEscape(r.Version)
	if r.Group == "" {
		prefix = "/api/" + url.PathEscape(r.Version)
	}
	u := c.Server + prefix + "/namespaces/" + url.PathEscape(req.Namespace) + "/" + url.PathEscape(r.Resource) + "/" + url.PathEscape(req.Name)
	hr, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return nil, err
	}
	hr.Header.Set("Authorization", "Bearer "+strings.TrimSpace(string(token)))
	hr.Header.Set("Accept", "application/json")
	resp, err := c.Client.Do(hr)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxReview))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET %s: %s", u, resp.Status)
	}
	var o struct {
		Metadata struct {
			Annotations map[string]string `json:"annotations"`
		} `json:"metadata"`
	}
	if err := json.Unmarshal(body, &o); err != nil {
		return nil, fmt.Errorf("GET %s: %w", u, err)
	}
	return o.Metadata.Annotations, nil
}
