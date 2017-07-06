#!/bin/bash

# bash script to be run either on a linux host or inside an already created arch
# linux docker container (arch-devel).

# fail fast
set -e

# get required tooling to create root tarball
pacman -S wget tar --noconfirm

# define path to extract to
bootstrap_extract="/tmp/extract"

# define archlinux download site
archlinux_download_site="https://archive.archlinux.org"

# define date of bootstrap tarball
bootstrap_date="2017.07.01"

# define today's date, used for filename for root tarball we create
todays_date=$(date +%Y-%m-%d)

# define input tarball filename
bootstrap_gzip_tarball="archlinux-bootstrap.tar.gz"

# define input tarball filename
root_bz2_tarball="archlinux-root-${todays_date}.tar.bz2"

# remove previously created root tarball (if it exists)
rm "${root_bz2_tarball}" || true

# create extraction path
mkdir -p "${bootstrap_extract}"; cd "${bootstrap_extract}"

# download bootstrap gzipped tarball from arch linux using wildcards
wget -r --no-parent -nH --cut-dirs=3 -e robots=off --reject "index.html" "${archlinux_download_site}/iso/${bootstrap_date}/" -A "archlinux-bootstrap*.tar.gz"

# rename gzipped tarball to known filename
mv archlinux-bootstrap*.tar.gz "${bootstrap_gzip_tarball}"

# identify if bootstrap gzipped tarball has top level folder, if so we need to remove it
tar -tf "${bootstrap_gzip_tarball}" | head

# extract gzipped tarball to remove top level folder 'root.x86_64'
tar -xvf "${bootstrap_gzip_tarball}" --strip 1

# remove downloaded tarball to prevent inclusion in new root tarball
rm -rf "${bootstrap_gzip_tarball}"

# remove empty folder from /
rm -rf ./x86_64 || true

# create text file detailing build date
echo "bootstrap tarball creation date: ${bootstrap_date}" >> ./build.txt
echo "root tarball creation date: $(date)" >> ./build.txt

# tar and bz2 compress again, excluding folders we dont require for docker usage
tar -cvpjf ../"${root_bz2_tarball}" --exclude=./ext --exclude=./etc/hosts --exclude=./etc/hostname --exclude=./etc/resolv.conf --exclude=./sys --exclude=./usr/share/man --exclude=./usr/share/gtk-doc --exclude=./usr/share/doc --exclude=./usr/share/locale --exclude=./usr/lib/systemd --one-file-system .

# remove extracted folder to tidy up after tarball creation
rm -rf "${bootstrap_extract}"

# upload to github for use in arch-scratch
