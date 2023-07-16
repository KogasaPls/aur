#!/bin/bash

# This script will update the PKGBUILD file with the latest release information.

_current_json=$(cat "latest.json")
_latest_release_url='https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest'
_latest_release_json=$(curl -s "$_latest_release_url")

_current_tag=$(echo "$_current_json" | jq -r '.tag_name')
_latest_tag=$(echo "$_latest_release_json" | jq -r '.tag_name')

main() {
  if [ "$_current_tag" == "$_latest_tag" ]; then
    echo "PKGBUILD is already up to date (${_current_tag})"
    exit 0
  fi

  local pkgver
  local sha512sum

  pkgver=$(get_pkgver)
  sha512sum=$(get_sha512sum)

  echo "Updating PKGBUILD from ${_current_tag} to ${_latest_tag}"

  echo "$_current_json" |
    jq -r '.tag_name |= "'"$_latest_tag"'"' |
    jq -r ".pkgver |= \"${pkgver}\"" |
    jq -r ".sha512sum |= \"${sha512sum}\"" >latest.json

  update_pkgbuild
}

get_pkgver() {
  echo "${_latest_tag#GE-Proton}" | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

get_sha512sum() {
  local asset_name
  local jq_string
  local url
  local sha512sum

  asset_name="wine-lutris-${_latest_tag}-x86_64.sha512sum"
  jq_string=".assets[] | select(.name==\"${asset_name}\") | .browser_download_url"
  url=$(echo "$_latest_release_json" | jq -r "$jq_string")

  if ! [ -f "$asset_name" ]; then
    curl -LJOs "$url"
  fi

  sha512sum=$(cut -d' ' -f1 <"$asset_name")
  rm "$asset_name"

  echo "$sha512sum"
}

update_pkgbuild() {
  local pkgbuild

  pkgbuild=$(cat PKGBUILD)
  pkgbuild=$(echo "$pkgbuild" | sed "s/pkgver=.*/pkgver=${pkgver}/" | sed  "s/_sha512sum=.*/_sha512sum=${sha512sum}/" | sed "s/_release_tag=.*/_release_tag=${_latest_tag}/")

  echo "$pkgbuild" >PKGBUILD
}

main
