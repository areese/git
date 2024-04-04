#!/bin/sh
#
# Copyright (c) 2012 Avery Pennaraum
# Copyright (c) 2015 Alexey Shumkin
#

test_description='test git subtree --[no-]gpg-sign

This test verifies the basic operation of the add, merge, split, pull,
and push subcommands of git subtree with gpg signing enabled.
'

TEST_DIRECTORY=$(pwd)/../../../t
. "$TEST_DIRECTORY"/test-lib.sh
GNUPGHOME_NOT_USED=$GNUPGHOME
. "$TEST_DIRECTORY/lib-gpg.sh"

if ! test_have_prereq GPG
then
	skip_all='skip all test git subtree --[no-]gpg-sign, gpg not available'
	test_done
fi

# Use our own wrapper around test-lib.sh's test_create_repo, in order
# to set log.date=relative.  `git subtree` parses the output of `git
# log`, and so it must be careful to not be affected by settings that
# change the `git log` output.  We test this by setting
# log.date=relative for every repo in the tests.
subtree_test_create_repo () {
	test_create_repo "$1" &&
	git -C "$1" config log.date relative
}

test_create_commit () (
	repo=$1 &&
	commit=$2 &&
	cd "$repo" &&
	mkdir -p "$(dirname "$commit")" \
	|| error "Could not create directory for commit"
	echo "$commit" >"$commit" &&
	git add "$commit" || error "Could not add commit"
	git commit --gpg-sign -m "$commit" || error "Could not commit"
)

test_wrong_flag() {
	test_must_fail "$@" >out 2>err &&
	test_must_be_empty out &&
	grep "flag does not make sense with" err
}

last_commit_subject () {
	git log --pretty=format:%s -1
}

# Upon 'git subtree add|merge --squash' of an annotated tag,
# pre-2.32.0 versions of 'git subtree' would write the hash of the tag
# (sub1 below), instead of the commit (sub1^{commit}) in the
# "git-subtree-split" trailer.
# We imitate this behaviour below using a replace ref.
# This function creates 3 repositories:
# - $1
# - $1-sub (added as subtree "sub" in $1)
# - $1-clone (clone of $1)
test_create_pre2_32_repo () {
	subtree_test_create_repo "$1" &&
	subtree_test_create_repo "$1-sub" &&
	test_commit -C "$1" --gpg-sign main1 &&
	test_commit -C "$1-sub" --gpg-sign --annotate sub1 &&
	git -C "$1" subtree add --prefix="sub" --squash "../$1-sub" sub1 &&
	tag=$(git -C "$1" rev-parse FETCH_HEAD) &&
	commit=$(git -C "$1" rev-parse FETCH_HEAD^{commit}) &&
	git -C "$1" log -1 --format=%B HEAD^2 >msg &&
	test_commit -C "$1-sub" --gpg-sign --annotate sub2 &&
	git clone --no-local "$1" "$1-clone" &&
	new_commit=$(sed -e "s/$commit/$tag/" msg | git -C "$1-clone" commit-tree HEAD^2^{tree}) &&
	git -C "$1-clone" replace HEAD^2 $new_commit
}

test_expect_success GPGSSH 'shows short help text for -h' '
	test_expect_code 129 git subtree -h >out 2>err &&
	test_must_be_empty err &&
	grep -e "^ *or: git subtree pull" out &&
	grep -F -e "--[no-]annotate" out
'

test_done
