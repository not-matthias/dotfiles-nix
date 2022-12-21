function fish_prompt
    echo -n -s (set_color brblack) "["(date "+%H:%M")"] " (set_color white) (whoami):

    # set -g fish_prompt_pwd_dir_length 0
    # echo -n -s (set_color bryellow) (basename $PWD)
    # echo -n -s (set_color bryellow) (prompt_pwd)

	set_color bryellow
	if [ $PWD != $HOME ]
		echo -n (basename $PWD)
	else
		echo -n ~
	end

    echo -n -s (set_color white) (fish_git_prompt) '> ' (set_color normal)
end
