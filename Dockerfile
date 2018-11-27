FROM debian:stretch-slim

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH


# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8


RUN mkdir -p /usr/share/man/man1
# runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		build-essential \		
		ca-certificates \
		default-jre \
		ed \
		less \
		netbase \
		vim-tiny \
		fonts-texgyre \
		wget \
		gcc \
		unzip \
		java-common \
		libcommons-math3-java \
		perl \
		libfindbin-libs-perl \
		libcommons-compress-java \
		libcommons-jexl2-java \
		libcommons-logging-java \
		libjaxb-java \
		libngs-java \
		libsnappy-java \
		libxz-java \
		libhtsjdk-java \
		libjbzip2-java \
		fastqc \
		apt-utils \
		cpp \
		linux-libc-dev \
		g++ \
		gcc-multilib \
		imagemagick \
		libblas3 \
		libbz2-1.0 \
		libbz2-dev \
		libc6 \
		libcairo2 \
		libcurl3 \
		libgfortran3 \
		libglib2.0-0 \
		libgomp1 \
		libice6 \
		libicu57 \
		libjpeg62-turbo \
		liblapack3 \
		liblzma5 \
		libpango-1.0-0 \
		libpangocairo-1.0-0 \
		libpaper-utils \
		libpcre3 \
		libpng16-16 \
		libquadmath0 \
		libreadline7 \
		libsm6 \
		libtcl8.6 \
		libtiff5 \
		libtk8.6 \
		libx11.6 \
		libxext6 \
		libxss1 \
		libxt6 \
		ucf \
		unzip \
		xdg-utils \
		zip \
		zlib1g \
		r-base-core \
		r-base-dev \
		r-cran-boot \
		r-cran-class \
		r-cran-cluster \
		r-cran-codetools \
		r-cran-foreign \
		r-cran-kernsmooth \
		r-cran-lattice \
		r-cran-littler \
		r-cran-stringr \
		r-cran-mass \
		r-cran-matrix \
		r-cran-mgcv \
		r-cran-nlme \
		r-cran-nnet \
		r-cran-rpart \
		r-cran-spatial \
		r-cran-survival \
		r-recommended \
		r-cran-xml \
		slurm \

	&& rm -rf /var/lib/apt/lists/*

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.7.1

RUN set -ex \
	\
	&& savedAptMark="$(apt-mark showmanual)" \
	&& apt-get update && apt-get install -y --no-install-recommends \
		wget \
		dpkg-dev \
		gcc \
		libbz2-dev \
		libc6-dev \
		libexpat1-dev \
		libffi-dev \
		libgdbm-dev \
		liblzma-dev \
		libncursesw5-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		tk-dev \
		uuid-dev \
		wget \
		xz-utils \
		zlib1g-dev \
		


# as of Stretch, "gpg" is no longer included by default
		$(command -v gpg > /dev/null || echo 'gnupg dirmngr') \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
	&& make install \
	&& ldconfig \
	\
	&& apt-mark auto '.*' > /dev/null \
	&& apt-mark manual $savedAptMark \
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.1

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends wget; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

RUN	pip install joblib

RUN wget http://downloads.sourceforge.net/project/tagdust/tagdust-2.33.tar.gz ; \
	tar -xvf tagdust-2.33.tar.gz ; \
	cd tagdust-2.33 ; \
	./configure ; \
	make ; \
	make check ; \
	make install


RUN	cd  usr/bin/ ; \
	wget https://github.com/relipmoc/skewer/archive/master.zip ; \
	unzip master.zip ; \
	cd skewer-master ; \
	make ; \
	make install

RUN	cd /usr/local/ ; \	
	wget https://github.com/alexdobin/STAR/archive/2.6.0a.tar.gz ; \
	tar -xvf 2.6.0a.tar.gz ; \
	cd STAR-2.6.0a/source ; \
	make STAR

ENV PATH /usr/local/STAR-2.6.0a/source:$PATH

RUN	rm -r tagdust-2.33 ; \
	rm tagdust-2.33.tar.gz 

RUN	cd  usr/local/bin/ ; \
	wget http://downloads.sourceforge.net/project/subread/subread-1.4.6-p2/subread-1.4.6-p2-source.tar.gz ; \
	tar -xvf subread-1.4.6-p2-source.tar.gz ; \
	cd subread-1.4.6-p2-source/src ; \
	make -f Makefile.Linux



ENV PATH /usr/local/bin/subread-1.4.6-p2-source/bin:$PATH





## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
        && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default 

ENV R_BASE_VERSION 3.5.1


RUN apt-get update \
	&& apt-get install -t unstable -y --no-install-recommends \
		libcurl4-gnutls-dev \
		littler \
                r-cran-littler \
                r-cran-stringr \
		r-base=${R_BASE_VERSION}-* \
		r-base-dev=${R_BASE_VERSION}-* \
		r-recommended=${R_BASE_VERSION}-* \
        && echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"))' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
&& rm -rf /var/lib/apt/lists/*


RUN R -e "install.packages('BiocManager', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('evaluate', repos = 'http://cran.us.r-project.org')"
RUN R -e "library(BiocManager)" ; \
	"BiocManager::install("CAGEr")"
