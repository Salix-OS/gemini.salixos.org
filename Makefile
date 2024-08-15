SSH_HOST=salixos.org
SSH_PORT=22
SSH_USER=web
SSH_TARGET_DIR=/srv/www/gemini/content/
BLOG_DIR=../blog.salixos.org/content/post
DOCS_DIR=../docs.salixos.org/content

.PHONY: update-posts
update-posts:
	for i in $$( ls $(BLOG_DIR) ); do \
		NAME=$$( echo $$i ); \
		BASENAME=$$( echo $$NAME | sed "s/\.md$$//" ); \
		if [ ! -d content/post/$$BASENAME ]; then \
			mkdir content/post/$$BASENAME; \
			if echo $$NAME | grep -q '.md$$'; then \
				TITLE=$$( head -n 10 $(BLOG_DIR)/$$NAME | grep "^title:" | sed "s/^title: \"\(.*\)\"/\1/" ); \
				DATE=$$( head -n 10 $(BLOG_DIR)/$$NAME | grep "^date:" | sed "s/^date: //" | cut -d'T' -f1 ); \
				echo -e "# $$TITLE\n" > content/post/$$BASENAME/index.gmi; \
				echo -e "Published $$DATE\n" >> content/post/$$BASENAME/index.gmi; \
				md2gemini -f -l paragraph $(BLOG_DIR)/$$NAME >> content/post/$$BASENAME/index.gmi; \
				dos2unix content/post/$$BASENAME/index.gmi; \
				echo "$$DATE $$TITLE $$BASENAME" >> content/post/dates-and-titles.txt; \
			else \
				TITLE=$$( head -n 10 $(BLOG_DIR)/$$NAME/index.md | grep "^title:" | sed "s/^title: \"\(.*\)\"/\1/" ); \
				DATE=$$( head -n 10 $(BLOG_DIR)/$$NAME/index.md | grep "^date:" | sed "s/^date: //" | cut -d'T' -f1 ); \
				echo -e "# $$TITLE\n" > content/post/$$BASENAME/index.gmi; \
				echo -e "Published $$DATE\n" >> content/post/$$BASENAME/index.gmi; \
				md2gemini -f -l paragraph $(BLOG_DIR)/$$NAME/index.md >> content/post/$$BASENAME/index.gmi; \
				dos2unix content/post/$$BASENAME/index.gmi; \
				echo "$$DATE $$TITLE $$BASENAME" >> content/post/dates-and-titles.txt; \
				cp $(BLOG_DIR)/$$NAME/*.{png,jpg} content/post/$$BASENAME/; \
			fi; \
		fi; \
	done
	echo -e "# Salix Posts\n\n" > content/post/index.gmi
	sort content/post/dates-and-titles.txt | tac | sed "s/\(.*\) \(.*\)/=> \2 \1/" >> content/post/index.gmi

.PHONY: update-docs
update-docs:
	for i in $$( find $(DOCS_DIR) -type f -name "_index.md" ); do \
		MD_FILE=$$( echo $$i ); \
		SOURCE_DIR=$$( echo $$MD_FILE | sed "s|_index.md||" ); \
		BASE_DIR=.$$( dirname $$MD_FILE | sed "s|$(DOCS_DIR)||" )/; \
		TARGET_DIR="content/docs/$$BASE_DIR/"; \
		mkdir -p $$TARGET_DIR; \
		SOURCE_MD5=$$( cat $$SOURCE_DIR/* 2> /dev/null| md5sum | cut -d" " -f1 ); \
		TARGET_MD5=$$( cat $$TARGET_DIR/page.md5 2> /dev/null | cut -d" " -f1 ); \
		if [ x"$$SOURCE_MD5" != x"$$TARGET_MD5" ] && [ ! -f $$TARGET_DIR/page.locked ]; then \
			echo "Found changes: $$SOURCE_DIR"; \
			rm -f $$TARGET_DIR/* 2> /dev/null; \
			echo $$SOURCE_MD5 > $$TARGET_DIR/page.md5; \
			cp $$SOURCE_DIR/*{png,jpg} $$TARGET_DIR/ 2> /dev/null; \
			TITLE=$$( head -n 10 $$SOURCE_DIR/_index.md | grep "^title:" | sed "s/^title: \"\(.*\)\"/\1/" | sed "s/^title: \(.*\)/\1/"  ); \
			echo -e "# $$TITLE\n" > $$TARGET_DIR/index.gmi;\
			md2gemini -p -f -l copy $$SOURCE_DIR/_index.md >> $$TARGET_DIR/index.gmi; \
			dos2unix -q $$TARGET_DIR/index.gmi; \
			sed -i "s|^=> /|=> /docs/|" $$TARGET_DIR/index.gmi; \
			sed -i "s|{{% notice warning %}}|WARNING:|" $$TARGET_DIR/index.gmi; \
			sed -i "s|{{% notice tip %}}|TIP:|" $$TARGET_DIR/index.gmi; \
			sed -i "s|{{% notice note %}}|NOTE:|" $$TARGET_DIR/index.gmi; \
			sed -i "s|{{% /notice %}}||" $$TARGET_DIR/index.gmi; \
		fi; \
	done; \
	for i in $$( find content/docs/ -type d ); do \
		ls -l $$i | grep -q "^d" && \
			echo "Removing lists from index page: $$i/index.gmi" && \
			sed -i "/^* /d" $$i/index.gmi; \
	done; \
	echo "Done"

.PHONY: upload
upload:
	rsync -e "ssh -p $(SSH_PORT)" \
		-avz \
		--exclude dates-and-titles.txt \
		--exclude page.md5 \
		--exclude page.locked \
		--delete ./content/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

.PHONY: serve
serve:
	agate --content content/ --certs certificates/ --hostname localhost
