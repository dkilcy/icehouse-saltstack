# Disable warnings after installing apache-libcloud
disable_libgmp_warning:
  file.replace:
    - name: /usr/lib64/python2.6/site-packages/Crypto/Util/number.py
    - pattern: 'if _fastmath is not None and not _fastmath.HAVE_DECL_MPZ_POWM_SEC:'
    - repl: '#if _fastmath is not None and not _fastmath.HAVE_DECL_MPZ_POWM_SEC:'
disable_RandomPool_warning_line1:
  file.replace:
    - name: /usr/lib64/python2.6/site-packages/Crypto/Util/randpool.py
    - pattern: 'warnings.warn\("This application uses RandomPool'
    - repl: '#warnings.warn\("This application uses RandomPool'
disable_RandomPool_warning_line2:
  file.replace:
    - name: /usr/lib64/python2.6/site-packages/Crypto/Util/randpool.py
    - pattern: 'RandomPool_DeprecationWarning\)'
    - repl: '#RandomPool_DeprecationWarning\)'

