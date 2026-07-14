CC      ?= gcc
CFLAGS  ?= -O2 -Wall -Wextra -pedantic -std=c99
LDFLAGS ?=

# pixman is only needed for benchmarks
PIXMAN_CFLAGS := $(shell pkg-config --cflags pixman-1 2>/dev/null)
PIXMAN_LIBS   := $(shell pkg-config --libs pixman-1 2>/dev/null)

.PHONY: all test bench demo clean

all: test bench demo

test: test_region
bench: bench_region
demo: demo_weston_repaint

test_region: test_region.c ph_region.c ph_region.h
	$(CC) $(CFLAGS) -o $@ test_region.c ph_region.c $(LDFLAGS)

bench_region: bench_region.c ph_region.c ph_region.h
	$(CC) $(CFLAGS) $(PIXMAN_CFLAGS) -o $@ bench_region.c ph_region.c $(LDFLAGS) $(PIXMAN_LIBS) -lm

demo_weston_repaint: demo_weston_repaint.c ph_region.c ph_region.h
	$(CC) $(CFLAGS) -o $@ demo_weston_repaint.c ph_region.c $(LDFLAGS)

clean:
	rm -f test_region bench_region demo_weston_repaint *.o
