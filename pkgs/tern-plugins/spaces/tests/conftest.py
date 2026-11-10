import pytest

from harness import linked, running


@pytest.fixture
def tern():
    with running() as instance:
        yield instance


@pytest.fixture
def machines():
    with linked() as pair:
        yield pair
