#!/bin/bash
# This merging script is used to compulse a "merged" branch from
# a previous split out of cpython's argument clinic tool, achieved
# with the following command line
# git-filter-repo --path Tools/clinic/ --path-glob README\* \
#   --path-rename Tools/clinic/:clinic-latest/ \
#   --path LICENSE --path CODE_OF_CONDUCT.md
# "merged" branch shall also be created before using this script.

gitismerge () {
    local sha1="$1"
    msha=$(git rev-list -1 --merges ${sha1}~1..${sha1})
    [ -z "$msha" ] && return 1
    return 0
}

pfx=""
if [ -d "clinic-3.$(expr $1 + 1)" ]; then
    git worktree add _wt_ v3.$1.$2
    pfx="_wt_/"
else
    git merge -X theirs --no-commit v3.$1.$2
    if [ ! "0" -eq $? ] || [ "-i" == "$3" ]; then
        git worktree add _wt_ v3.$1.$2
        /bin/bash -i
    fi
    [ ! -f ".gitm.sh" ] && cp $0 .gitm.sh
    [ ! -d "clinic-3.$1" ] && mkdir "clinic-3.$1"
fi
[ -d "clinic-3.$1/latest" ] && rm -fr "clinic-3.$1/latest"
cp -rl "${pfx}clinic-latest" "clinic-3.$1/latest"
cp -rl "${pfx}clinic-latest" "clinic-3.$1/v3.$1.$2"
[ -d "_wt_" ] && git worktree remove _wt_
echo "# $1 $2" >> .gitm.sh
git add "clinic-3.$1/v3.$1.$2" "clinic-3.$1/latest" .gitm.sh
tid=$(git write-tree)
echo "tree: $tid"
git cat-file -p $tid^{tree} | grep clinic-latest
git cat-file -p $tid^{tree}:clinic-3.$1
sha=$(git rev-parse HEAD)
branch=$(git rev-parse --abbrev-ref HEAD)
from=$(git rev-parse v3.$1.$2^{commit})
echo "parent: $sha"
[ "1" == "$(gitismerge $sha)" ] && exit 1
echo "processing new commit"
newc=$(git cat-file commit v3.$1.$2 | sed -e "s/^tree .*/tree $tid/" \
    -e "s/^parent .*/parent $sha\nparent $from/" | \
    git hash-object -t commit -w --stdin)
git reset -q --hard
git checkout -q $newc -b ${branch}-NEW
git branch -D ${branch}
git branch -M ${branch}-NEW ${branch}
git tag ${branch}-v3.$1.$2
# 5 0
# 5 2
# 6 0
# 5 3
# 6 4
# 7 0
# 7 1
# 7 3
# 8 0
# 8 3
# 7 8
# 9 0
# 9 1
# 8 7
# 10 0
# 9 8
# 9 13
# 10 5
# 10 6
# 10 8
# 11 0
# 11 1
# 10 10
# 11 2
# 11 5
