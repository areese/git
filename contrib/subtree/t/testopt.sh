
OPTS_SPEC="\
git subtree add   --prefix=<prefix> <commit>
git subtree add   --prefix=<prefix> <repository> <ref>
git subtree merge --prefix=<prefix> <commit>
git subtree split --prefix=<prefix> [<commit>]
git subtree pull  --prefix=<prefix> <repository> <ref>
git subtree push  --prefix=<prefix> <repository> <refspec>
--
h,help        show the help
q             quiet
d             show debug messages
P,prefix=     the name of the subdir to split out
 options for 'split' (also: 'push')
annotate=     add a prefix to commit message of new commits
b,branch=     create a new branch from the split subtree
ignore-joins  ignore prior --rejoin commits
onto=         try connecting new tree to an existing one
rejoin        merge the new branch back into HEAD
 options for 'add' and 'merge' (also: 'pull', 'split --rejoin', and 'push --rejoin')
squash        merge subtree changes as a single commit
m,message=    use the given message as the commit message for the merge commit
S,gpg-sign?   GPG-sign commits, optionally specifying keyid.
no-gpg-sign   Disable GPG commit signing.
"


echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@"

set_args="$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"
eval "$set_args"
	while test $# -gt 0
	do
		opt="$1"
		shift

		echo "opt : ${opt}"
		echo "opt1: ${1}"
		echo "opt2: ${2}"

		case "$opt" in
		-q)
			arg_quiet=1
			;;
		-d)
			arg_debug=1
			;;
		--annotate)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_annotate="$1"
			shift
			;;
		--no-annotate)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_annotate=
			;;
		-b)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_branch="$1"
			shift
			;;
		-P)
			arg_prefix="${1%/}"
			shift
			;;
		-m)
			test -n "$allow_addmerge" || die_incompatible_opt "$opt" "$arg_command"
			arg_addmerge_message="$1"
			shift
			;;
		--no-prefix)
			arg_prefix=
			;;
		--onto)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_onto="$1"
			shift
			;;
		--no-onto)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_onto=
			;;
		--rejoin)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			;;
		--no-rejoin)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			;;
		--ignore-joins)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_ignore_joins=1
			;;
		--no-ignore-joins)
			test -n "$allow_split" || die_incompatible_opt "$opt" "$arg_command"
			arg_split_ignore_joins=
			;;
		--squash)
			test -n "$allow_addmerge" || die_incompatible_opt "$opt" "$arg_command"
			arg_addmerge_squash=1
			;;
		--no-squash)
			test -n "$allow_addmerge" || die_incompatible_opt "$opt" "$arg_command"
			arg_addmerge_squash=
			;;
		-S|--gpg-sign|--no-gpg-sign)
			arg_gpgsign="${opt}"
			case $1 in
				-*)
					;;
				*)
					arg_gpgsign=${opt}${1}
					shift
					;;
			esac
			;;
		--)
			break
			;;
		*)
			echo "fatal: unexpected option: $opt"
			;;
		esac
	done
	shift
echo done

echo got ${arg_gpgsign}
