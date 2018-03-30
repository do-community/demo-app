release:
	tar -czf statuspage-demo.tar.gz \
		ansible \
		app/static app/main.go app/index.html \
		terraform \
		statuspage-destroy.sh
