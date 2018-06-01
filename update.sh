#!/bin/bash
set -e

case "$OSTYPE" in
 "darwin"*)
	command -v greadlink > /dev/null 2>&1 || { printf "GNU Cureutils is required to run $0\nAt the command line type 'brew install coreutils'\n\n">&2; exit 1;}
	command -v gsed > /dev/null 2>&1 || { printf "GNU sed is required to run $0\nAt the command line type 'brew install gnu-sed'\n\n">&2; exit 1;}
	command -v ggrep > /dev/null 2>&1 || { printf "GNU grep is required to run $0\nAt the command line type 'brew install grep'\n\n">&2; exit 1;}
	bin_readlink="greadlink"
	bin_sed="gsed"
	bin_grep="ggrep"
	#cd "$(dirname "$(greadlink -f "$BASH_SOURCE")")"
	;;
*)
	bin_readlink="readlink"
	bin_sed="sed"
	bin_grep="grep"
	#cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
	;;
esac
cd "$(dirname "$(eval $bin_readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

packagesUrl='http://repo.percona.com/apt/dists/jessie/main/binary-amd64/Packages'
packages="$(echo "$packagesUrl" | eval $bin_sed -r 's/[^a-zA-Z.-]+/-/g')"
curl -sSL "${packagesUrl}.gz" | gunzip > "$packages"

for version in "${versions[@]}"; do
	fullVersion="$(grep -h -A10 "^Package: percona-server-server-$version\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
	(
		set -x
		printf "Full Version: $fullVersion \n"
		eval $($bin_sed 's/%%PERCONA_MAJOR%%/'"$version"'/g;s/%%PERCONA_VERSION%%/'"$fullVersion"'/g;' Dockerfile.template > "$version/Dockerfile")
	)
done

rm "$packages"
