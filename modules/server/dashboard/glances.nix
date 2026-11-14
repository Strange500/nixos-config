{pkgs}:
# Backport the PyJWT migration from Glances upstream (e41c538233b0253ff84d8121518fbce207fb3354)
# to 4.5.7 rather than allowing python-jose's CVE-2026-120459.
pkgs.glances.overridePythonAttrs (old: {
  # Rebuilding exposes fixed-delay REST tests on slow CI runners. Wait for
  # readiness instead, retaining all upstream tests and their assertions.
  patches = (old.patches or []) ++ [./glances-test-readiness.patch];

  dependencies =
    builtins.filter (dep: (dep.pname or "") != "python-jose") old.dependencies
    ++ [pkgs.python3Packages.pyjwt];

  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace glances/jwt_utils.py \
        --replace-fail 'from jose import JWTError, jwt' 'import jwt; from jwt import PyJWTError as JWTError' \
        --replace-fail 'python-jose' 'PyJWT'
      substituteInPlace glances/outputs/glances_restful_api.py \
        --replace-fail 'python-jose' 'PyJWT'
      substituteInPlace pyproject.toml \
        --replace-fail 'python-jose[cryptography]>=3.3.0' 'PyJWT>=2.10.0'
      cp ${./test_glances_jwt.py} tests/test_glances_jwt.py
    '';
})
