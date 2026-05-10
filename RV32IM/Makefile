# Root Makefile

# 현재 디렉토리 및 하위 디렉토리에서 모든 makefile 경로를 찾는다.
SUBDIRS := $(shell find . -mindepth 2 -type f -name '[Mm]akefile' -exec dirname {} \;)

# 각 디렉토리에서 make clean을 실행하는 규칙 정의
.PHONY: clean
clean:
	@for dir in $(SUBDIRS); do \
		echo "Running make clean in $$dir"; \
		$(MAKE) -C $$dir clean; \
	done

