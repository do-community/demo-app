VERSION=0.0.1
TAG=v${VERSION}

release: check-env
	curl -XPOST \
		-H 'Accept: application/vnd.github.v3+json' \
		-H "Authorization: token $$GITHUB_TOKEN" \
		-d "{\"tag_name\": \"${TAG}\", \"name\": \"${TAG}\", \"body\": \"Release ${TAG}\", \"target_commitish\": \"$$(git rev-parse HEAD)\"}" \
		'https://api.github.com/repos/do-community/demo-app/releases'

check-env:
ifndef GITHUB_TOKEN
  $(error GITHUB_TOKEN is undefined)
endif

.PHONY: release check-env
