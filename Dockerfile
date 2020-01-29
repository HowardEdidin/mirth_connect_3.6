FROM java

ENV MIRTH_CONNECT_VERSION 3.6.0.b2287

RUN useradd -u 1000 mirth

RUN gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
# RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.11/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu
	
RUN set -eux; \
# save list of currently installed packages for later so we can clean up
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	if ! command -v gpg; then \
		apt-get install -y --no-install-recommends gnupg2 dirmngr; \
	elif gpg --version | grep -q '^gpg (GnuPG) 1\.'; then \
# "This package provides support for HKPS keyservers." (GnuPG 1.x only)
		apt-get install -y --no-install-recommends gnupg-curl; \
	fi; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.11/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true
	
	
VOLUME /opt/mirth-connect/appdata

RUN \
  cd /tmp && \
  wget http://downloads.mirthcorp.com/archive/connect/$MIRTH_CONNECT_VERSION/mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  tar xvzf mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  rm -f mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  mv Mirth\ Connect/* /opt/mirth-connect/ && \
  chown -R mirth /opt/mirth-connect
  

COPY mirth.properties /tmp
COPY extension.properties /tmp
COPY fhir.tar.gz /tmp
COPY net.sourceforge.lpg.lpgjavaruntime_1.1.0.v200803061910.jar /tmp
COPY org.eclipse.emf.common_2.5.0.v200906151043.jar /tmp
COPY org.eclipse.emf.ecore.xmi_2.5.0.v200906151043.jar /tmp
COPY org.eclipse.emf.ecore_2.5.0.v200906151043.jar /tmp
COPY org.eclipse.ocl.ecore_1.3.0.v200905271400.jar /tmp
COPY org.eclipse.ocl_1.3.0.v200905271400.jar /tmp
COPY org.openhealthtools.mdht.emf.runtime_1.0.0.201212201425.jar /tmp
COPY org.openhealthtools.mdht.uml.cda_1.2.0.201212201425.jar /tmp
COPY org.openhealthtools.mdht.uml.hl7.datatypes_1.2.0.201212201425.jar /tmp
COPY org.openhealthtools.mdht.uml.hl7.rim_1.2.0.201212201425.jar /tmp
COPY org.openhealthtools.mdht.uml.hl7.vocab_1.2.0.201212201425.jar /tmp


RUN \
 cp -af /tmp/net.sourceforge.lpg.lpgjavaruntime_1.1.0.v200803061910.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.eclipse.emf.common_2.5.0.v200906151043.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.eclipse.emf.ecore.xmi_2.5.0.v200906151043.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.eclipse.emf.ecore_2.5.0.v200906151043.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.eclipse.ocl.ecore_1.3.0.v200905271400.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.eclipse.ocl_1.3.0.v200905271400.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.openhealthtools.mdht.emf.runtime_1.0.0.201212201425.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.openhealthtools.mdht.uml.cda_1.2.0.201212201425.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.openhealthtools.mdht.uml.hl7.datatypes_1.2.0.201212201425.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.openhealthtools.mdht.uml.hl7.rim_1.2.0.201212201425.jar /opt/mirth-connect/custom-lib/ && \
 cp -af /tmp/org.openhealthtools.mdht.uml.hl7.vocab_1.2.0.201212201425.jar /opt/mirth-connect/custom-lib/  && \
 cp -af /tmp/mirth.properties /opt/mirth-connect/conf/ && \
 cp -af /tmp/extension.properties /opt/mirth-connect/appdata/ && \
 cp -af /tmp/fhir.tar.gz /opt/mirth-connect/extensions/ && \ 
 cd /opt/mirth-connect/extensions/ && \
 tar -xzvf fhir.tar.gz && \
 rm -f fhir.tar.gz 



WORKDIR /opt/mirth-connect

EXPOSE 8080 8443

COPY docker-entrypoint.sh /


RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]


CMD ["java", "-jar", "mirth-server-launcher.jar"]
