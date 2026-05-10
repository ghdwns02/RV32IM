# 디렉토리 목록 정의
SUBDIRS = cachetest fib replace strcmp sum vecadd

# 기본 타겟 정의
.PHONY: all $(SUBDIRS)
all: $(SUBDIRS)

# 각 서브 디렉토리에서 make 실행
$(SUBDIRS):
	@echo "Entering directory '$@'"
	@$(MAKE) -C $@ --no-print-directory

# 청소 (clean) 타겟 정의 - 각 디렉토리에서 clean 수행
.PHONY: clean
clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

