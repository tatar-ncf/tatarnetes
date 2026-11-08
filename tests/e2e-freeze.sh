#!/usr/bin/env bash
# Тыю вебхугын kind кластерында тикшерү / end-to-end test of the change-freeze
# webhook on a kind cluster: install the chart with a pretended holiday
# (Sabantuy 2026), then act as a human and as the cluster's own controllers.
#
# Needs: a kind cluster as the current kubectl context, helm, docker.
#   CERT_MODE=helm|cert-manager   how the serving certificate is made
#   KIND_CLUSTER=kind              the kind cluster to load the image into
set -euo pipefail

CERT_MODE="${CERT_MODE:-helm}"
KIND_CLUSTER="${KIND_CLUSTER:-kind}"
NS=freeze
REL=freeze
HOLIDAY=2026-06-20   # Sabantuy, a verified date of data/holidays.tt
ORDINARY=2026-06-19
HUMAN=(--as=alsu --as-group=system:authenticated)
BREAK=tatar-ncf.github.io/break-glass

cd "$(dirname "$0")/.."
fails=0
pass() { echo "  ok   $*"; }
fail() { echo "  FAIL $*"; fails=$((fails + 1)); }
step() { echo; echo "== $*"; }
show() { while IFS= read -r l; do echo "       $l"; done <<<"$1"; }

# expect_denied <description> <command...>: the command fails with the
# freeze's message in both languages.
expect_denied() {
	local what=$1 out
	shift
	if out=$("$@" 2>&1); then
		fail "$what: allowed, want denied"; show "$out"; return
	fi
	if grep -q 'denied the request' <<<"$out" && grep -q 'Бүген Сабан туе' <<<"$out" &&
		grep -q 'мәйданында үзгәрешләр тыела' <<<"$out" && grep -q 'Today is Sabantuy' <<<"$out" &&
		grep -q 'are frozen' <<<"$out" && grep -q "$BREAK" <<<"$out"; then
		pass "$what: denied in Tatar and English"
	else
		fail "$what: failed without the freeze's message"; show "$out"
	fi
}

# expect_allowed <description> <warning-regex|-> <command...>: the command
# succeeds; with a regex, a Warning: line matches it; with -, no Warning:.
expect_allowed() {
	local what=$1 want=$2 out
	shift 2
	if ! out=$("$@" 2>&1); then
		fail "$what: denied, want allowed"; show "$out"; return
	fi
	if [[ $want == - ]]; then
		if grep -q '^Warning:' <<<"$out"; then
			fail "$what: unexpected warning"; show "$out"
		else
			pass "$what: allowed, no warning"
		fi
	elif grep '^Warning:' <<<"$out" | grep -Eq "$want"; then
		pass "$what: allowed with warning"
	else
		fail "$what: allowed but no warning matching /$want/"; show "$out"
	fi
}

install() { # install <today> [helm args...]
	local today=$1
	shift
	helm upgrade --install "$REL" charts/tatarnetes-freeze -n "$NS" --create-namespace --wait --timeout 3m \
		--set image.repository=tatarnetes-freeze --set image.tag=e2e --set image.pullPolicy=Never \
		--set replicas=1 --set today="$today" --set certManager.enabled="$([[ $CERT_MODE == cert-manager ]] && echo true || echo false)" "$@"
	kubectl -n "$NS" rollout status deploy/"$REL" --timeout=2m
}

# wait_for_freeze: failurePolicy is Ignore, so until the webhook answers,
# changes go through; wait until a probe change is actually denied.
wait_for_freeze() {
	for _ in $(seq 60); do
		if ! kubectl "${HUMAN[@]}" -n shop create configmap probe --dry-run=server -o name >/dev/null 2>&1; then
			return 0
		fi
		sleep 2
	done
	echo "the webhook never started denying"; kubectl -n "$NS" logs deploy/"$REL" --tail=50 || true
	exit 1
}

step "image"
docker build -q -f freeze/Dockerfile -t tatarnetes-freeze:e2e .
kind load docker-image tatarnetes-freeze:e2e --name "$KIND_CLUSTER"

if [[ $CERT_MODE == cert-manager ]]; then
	step "cert-manager"
	helm repo add jetstack https://charts.jetstack.io --force-update >/dev/null
	helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace \
		--set crds.enabled=true --wait --timeout 5m
fi

step "workloads, before any namespace opts in"
kubectl create clusterrolebinding alsu-admin --clusterrole=cluster-admin --user=alsu --dry-run=client -o yaml | kubectl apply -f -
for ns in shop bazaar plain; do
	kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n "$ns" create deployment web --image=registry.k8s.io/pause:3.10 --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n "$ns" create configmap menu --from-literal=dish=chakchak --dry-run=client -o yaml | kubectl apply -f -
done
kubectl -n shop create configmap old --from-literal=a=b --dry-run=client -o yaml | kubectl apply -f -
for ns in shop bazaar plain; do kubectl -n "$ns" rollout status deploy/web --timeout=2m; done
kubectl label namespace shop tatar-ncf.github.io/change-freeze=enforce --overwrite
kubectl label namespace bazaar tatar-ncf.github.io/change-freeze=warn --overwrite

step "install the chart ($CERT_MODE certificate), today = Sabantuy $HOLIDAY"
install "$HOLIDAY"
wait_for_freeze

step "enforce namespace (shop), as a human"
expect_denied "create configmap" kubectl "${HUMAN[@]}" -n shop create configmap new --from-literal=a=b
expect_denied "edit configmap" kubectl "${HUMAN[@]}" -n shop label configmap menu spicy=yes
expect_denied "rollout restart" kubectl "${HUMAN[@]}" -n shop rollout restart deploy/web
expect_denied "delete configmap" kubectl "${HUMAN[@]}" -n shop delete configmap old
expect_denied "delete pod" kubectl "${HUMAN[@]}" -n shop delete pod -l app=web --wait=false
expect_denied "set image" kubectl "${HUMAN[@]}" -n shop set image deploy/web pause=registry.k8s.io/pause:3.9

step "never frozen: leases, events, nodes"
expect_allowed "create lease" - kubectl "${HUMAN[@]}" -n shop apply -f - <<'EOF'
apiVersion: coordination.k8s.io/v1
kind: Lease
metadata: {name: e2e}
spec: {holderIdentity: alsu}
EOF
expect_allowed "create event" - kubectl "${HUMAN[@]}" -n shop create -f - <<'EOF'
apiVersion: v1
kind: Event
metadata: {generateName: e2e-}
involvedObject: {kind: ConfigMap, name: menu, namespace: shop}
reason: Test
message: a holiday event
type: Normal
EOF
node=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
expect_allowed "label node" - kubectl "${HUMAN[@]}" label node "$node" tatar-ncf.github.io/e2e=yes --overwrite

step "never frozen: the cluster's own controllers"
expect_allowed "garbage collector deletes" - \
	kubectl --as=system:serviceaccount:kube-system:generic-garbage-collector -n shop delete configmap old
expect_allowed "kube-system serviceaccount updates" - \
	kubectl --as=system:serviceaccount:kube-system:generic-garbage-collector -n shop annotate configmap menu e2e/gc=yes

step "break-glass"
expect_denied "empty reason" kubectl "${HUMAN[@]}" -n shop annotate deploy/web "$BREAK= "
expect_allowed "annotate break-glass" "Сабан туе.*$BREAK.*INC-42.*Today is Sabantuy" \
	kubectl "${HUMAN[@]}" -n shop annotate deploy/web "$BREAK=INC-42 payment outage"
expect_allowed "rollout restart under break-glass" "INC-42" \
	kubectl "${HUMAN[@]}" -n shop rollout restart deploy/web
# The deployment and replicaset controllers, the scheduler and the kubelet
# carry the rollout through in a frozen namespace.
if kubectl -n shop rollout status deploy/web --timeout=2m >/dev/null; then
	pass "controllers rolled the deployment out in a frozen namespace"
else
	fail "rollout did not finish in a frozen namespace"
fi
expect_allowed "delete under break-glass" "INC-42" kubectl "${HUMAN[@]}" -n shop delete deploy/web --wait=false
if kubectl -n "$NS" logs deploy/"$REL" | grep -q 'break-glass: DELETE deployments shop/web by alsu: INC-42'; then
	pass "break-glass delete logged"
else
	fail "break-glass delete not in the webhook's log"
fi

step "warn namespace (bazaar)"
expect_allowed "create configmap" "Сабан туе.*узды.*Today is Sabantuy.*an enforced freeze would deny it" \
	kubectl "${HUMAN[@]}" -n bazaar create configmap new --from-literal=a=b
expect_allowed "delete configmap" "Today is Sabantuy" kubectl "${HUMAN[@]}" -n bazaar delete configmap new

step "unlabelled namespace (plain)"
expect_allowed "create configmap" - kubectl "${HUMAN[@]}" -n plain create configmap new --from-literal=a=b
expect_allowed "rollout restart" - kubectl "${HUMAN[@]}" -n plain rollout restart deploy/web

step "helm upgrade: cluster-wide warn mode"
ca_before=$(kubectl -n "$NS" get secret "$REL-tls" -o jsonpath='{.data.ca\.crt}')
install "$HOLIDAY" --set mode=warn
sleep 3
expect_allowed "enforce namespace only warns" "Today is Sabantuy" \
	kubectl "${HUMAN[@]}" -n shop create configmap warned --from-literal=a=b
ca_after=$(kubectl -n "$NS" get secret "$REL-tls" -o jsonpath='{.data.ca\.crt}')
if [[ -n $ca_before && $ca_before == "$ca_after" ]]; then
	pass "serving CA kept across helm upgrade"
else
	fail "serving CA changed across helm upgrade"
fi

step "an ordinary day ($ORDINARY)"
install "$ORDINARY"
sleep 3
expect_allowed "enforce namespace, ordinary day" - kubectl "${HUMAN[@]}" -n shop create configmap ordinary --from-literal=a=b
expect_allowed "delete configmap, ordinary day" - kubectl "${HUMAN[@]}" -n shop delete configmap ordinary

echo
if ((fails)); then
	echo "◆ $fails check(s) failed"
	kubectl -n "$NS" logs deploy/"$REL" --tail=100 || true
	exit 1
fi
echo "◆ Тыю вебхугы тикшерелде / the change freeze passed end to end ($CERT_MODE)"
