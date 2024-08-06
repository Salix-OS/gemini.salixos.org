SSH_HOST=salixos.org
SSH_PORT=22
SSH_USER=web
SSH_TARGET_DIR=/srv/www/gemini/content/
BLOG_DIR=../blog.salixos.org/content/post

.PHONY: update-posts
update-posts:
	for i in $$( ls ../blog.salixos.org/content/post/ ); do \
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

.PHONY: upload
upload:
	rsync -e "ssh -p $(SSH_PORT)" \
		-avz \
		--exclude dates-and-titles.txt \
		--delete ./content/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

.PHONY: serve
serve:
	agate --content content/ --certs certificates/ --hostname localhost
