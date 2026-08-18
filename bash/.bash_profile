# ~/.bash_profile: executed by bash for login shells.
#
# macOS terminals start LOGIN shells by default, so this file is what runs there
# and ~/.bashrc would never be read without the source below. Keep it thin —
# everything real lives in ~/.bashrc so login and non-login shells match.

# Source ~/.bashrc if it exists
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
