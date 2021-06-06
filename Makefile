
all: version.txt en

en: build/latex/en.pdf

de: build/latex/de.pdf

build/:
	mkdir -p $@

build/latex/:
	mkdir -p $@

version.txt:
ifeq ($(shell git describe --always --contains HEAD | grep -E "\^0$$"),)
	@echo "Candidate"
	printf "%s-" $$(git describe HEAD | grep -Eo "^[0-9]+\.[0-9]+-(Final|Draft)\+[0-9]+") > $@
	git rev-parse --short=4 HEAD >> $@
else
	@echo "Release"
	(git describe HEAD | grep -Eo "^[0-9]+\.[0-9]+-(Final|Draft)\+[0-9]+") > $@
endif

latex/version.tex: version.txt
	@printf "\\providecommand*{\\\ruleversion}{" > $@
	grep -E "^([0-9]+)\.([0-9]+)-(Draft|Final)\+[0-9]+-[a-z0-9]+$$" $< | sed -E 's#^([0-9]+)\.([0-9]+)-(Draft|Final)\+([a-z0-9]+)(-?[a-z0-9]*)$$#\1.\2\5\\version\3}#' >> $@

build/latex/%.tex: rules/%.md | build/latex/
	pandoc --from markdown --to latex --output $@ -- $<
	sed -i '/\\def\\labelenumi/d' $@
	sed -i 's/\\tightlist/\\tightlist{}/' $@

build/latex/%.pdf: latex/%.tex latex/precommon.tex latex/common.tex build/latex/%.tex latex/version.tex | build/latex/
	latexmk -cd- -pdflualatex -file-line-error -halt-on-error -interaction=nonstopmode -output-directory=$(dir $@) $<

check: check-markdown check-latex

check-latex: $(filter-out latex/version.tex,$(wildcard latex/*.tex)) $(wildcard build/latex/*.tex)
	chktex --localrc .chktexrc -- $^

check-markdown: $(wildcard *.md) $(wildcard rules/*.md)
	markdownlint --config .markdownlint.yaml -- $^

clean:
	$(RM) -r build/
	$(RM) version.txt latex/version.tex

.PHONY = en de all clean check check-latex check-markdown
