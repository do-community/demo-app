release: check-env check-readme
	export TAG=v`cat VERSION` && \
	export COMMIT=`git rev-parse HEAD` && \
		curl -XPOST \
			-H 'Accept: application/vnd.github.v3+json' \
			-H "Authorization: token $$GITHUB_TOKEN" \
			-d "{\"tag_name\": \"$$TAG\", \"name\": \"$$TAG\", \"body\": \"Release $$TAG\", \"target_commitish\": \"$$COMMIT\"}" \
			'https://api.github.com/repos/do-community/demo-app/releases'

check-env:
ifndef GITHUB_TOKEN
  $(error GITHUB_TOKEN is undefined)
endif

check-readme:
ifeq ($(shell grep -q version=\"`cat VERSION`\" README.md; echo $$?),1)
	$(error REAMDME.md does not reference the correct version of statuspage-launch.sh.)
endif

.PHONY: release check-env check-readme
