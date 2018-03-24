FROM centos:centos7
MAINTAINER Health Catalyst <imran.qureshi@healthcatalyst.com>

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
	&& mkdir -p /home/docker \
	&& chown docker:docker /home/docker
 
RUN yum -y update; yum clean all
RUN yum -y install epel-release; yum clean all

# install packages for authentication with Active Directory
RUN yum -y install authconfig krb5-workstation pam_krb5 samba-common oddjob-mkhomedir sudo ntp; yum clean all

# create /opt/install folder
# RUN mkdir -p /opt/install/

# add script to create keytab file for kerberos authentication with Active Directory
ADD https://healthcatalyst.github.io/InstallScripts/setupkeytab.txt /opt/install/setupkeytab.sh
ADD https://healthcatalyst.github.io/InstallScripts/signintoactivedirectory.txt /opt/install/signintoactivedirectory.sh
ADD https://healthcatalyst.github.io/InstallScripts/testsql.txt /opt/install/testsql.sh

RUN chmod +x /opt/install/setupkeytab.sh \
    && chmod +x /opt/install/signintoactivedirectory.sh \
    && chmod +x /opt/install/testsql.sh
    

# RUN ls -ld /usr/lib64/R/library

RUN mkdir -p /usr/lib64/R/library \
    && chown docker:docker /usr/lib64/R/library \
    && mkdir -p /usr/share/doc/R-3.3.3/html \
    && chown docker:docker /usr/lib64/R/library 

# Install MSSQL driver
RUN curl -o /etc/yum.repos.d/mssql-release.repo https://packages.microsoft.com/config/rhel/7/prod.repo && echo "curled" \
    && yum remove unixODBC-utf16 unixODBC-utf16-devel \
    && ACCEPT_EULA=Y yum install -y msodbcsql-13.1.4.0-1 mssql-tools-14.0.3.0-1 unixODBC-devel && echo "installed" \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile && echo "exported to bash_profile" \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && echo "exported to bashrc" \
    && source ~/.bashrc

# CentOS 7 does not have bzip2 and miniconda requires it for installation
RUN yum -y install bzip2; yum clean all

RUN curl -N https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh --output usr/src/Miniconda.sh \
   && bash usr/src/Miniconda.sh -b -p /opt/conda \
   && source /opt/conda/bin/activate \
   && /opt/conda/bin/conda install -y numpy \
   && /opt/conda/bin/conda list \
   && /opt/conda/bin/conda update -n base conda

ENV PATH /opt/conda/bin:$PATH

# ____________________ Airflow ____________________
# install airflow
RUN pip install 
RUN conda install -c conda-forge airflow
# Copy config and DAGs from repo into airflow_home directory
# RUN mkdir /root/airflow
# ADD dags /root/airflow
# ADD airflow.cfg /root/airflow
# Initialize SQLite (not production grade) airflow db
RUN airflow initdb

# RUN mkdir -p /usr/share/fabricml

EXPOSE 8080

CMD ["airflow", "webserver"]
