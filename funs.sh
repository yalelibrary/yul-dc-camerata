#refactored from other scripts, complete with gross hack to support scripts taht don't care about .secrets
#args: 
#$1 is cluster name
#$2, optional is a filename to check for the presence of

check_files() {
  for var in "$@"; do
    if [[ ! -f ${var} ]]; then
      echo "The file '$var' is required to exist."
      code=1
      break
    fi
  done
  return $code || 0
}

check_name () {
  if [[ -z $1 ]];then
    echo "Please supply a cluster name as the first argument to this script."
    return 1
  else
    return 0
  fi
}

# assert that list of env variables is set to non-blank value
check_vars() {
  for var in "$@"; do
    if [[ -z ${!var} ]]; then
      echo "Error: Please set ${var} in your environment using \"export $var=your_value\"\n"
      return 1
    fi
  done
  return 0
}

check_secrets() {
  if [[ -f "${1}" ]] 
  then
    local somefile='ok'
  else
    echo "ERROR: Please provide a \"$somefile\" file.  See \"$somefile-template\" for an example."
    return 1
  fi
  return 0

}
check_exec() {
  if $(which -s "${1}")  ; then
    return 0
  else
    echo "$1 binary not found. Please install it."
    return 1
  fi
}

