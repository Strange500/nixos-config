"""Regression coverage for the Glances 4.x backport from python-jose to PyJWT."""

from datetime import datetime, timedelta, timezone

import jwt
import pytest

from glances.jwt_utils import JWTHandler


SECRET = "glances-regression-test-secret-at-least-32-bytes"


def test_token_round_trip():
    handler = JWTHandler(secret_key=SECRET)
    assert handler.is_available
    token = handler.create_access_token("glances-user")
    assert handler.verify_token(token) == "glances-user"
    assert jwt.decode(token, SECRET, algorithms=["HS256"])["iss"] == "glances"


@pytest.mark.parametrize("case", ["expired", "wrong-key", "wrong-algorithm", "missing-subject", "malformed"])
def test_invalid_tokens_are_rejected(case):
    handler = JWTHandler(secret_key=SECRET)
    payload = {
        "sub": "glances-user",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=5),
    }
    key = SECRET
    algorithm = "HS256"
    if case == "expired":
        payload["exp"] = datetime.now(timezone.utc) - timedelta(minutes=5)
    elif case == "wrong-key":
        key = "a-different-secret-at-least-32-bytes-long"
    elif case == "wrong-algorithm":
        algorithm = "HS384"
    elif case == "missing-subject":
        del payload["sub"]
    token = "not.a.token" if case == "malformed" else jwt.encode(payload, key, algorithm=algorithm)
    assert handler.verify_token(token) is None


def test_generated_key():
    handler = JWTHandler()
    assert handler.is_available
    assert handler.verify_token(handler.create_access_token("generated-key-user")) == "generated-key-user"
