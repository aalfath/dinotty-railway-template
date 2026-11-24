# Debian's /etc/profile resets PATH for login shells; Dinotty opens login
# shells, so put the persistent per-user tool folders back in front.
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
case ":$PATH:" in
  *":$HOME/.npm-global/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH" ;;
esac
export PATH
