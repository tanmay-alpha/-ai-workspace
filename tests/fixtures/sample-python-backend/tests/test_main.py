import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from main import add, divide
import pytest


def test_add_positive():
    assert add(2, 3) == 5


def test_add_negative():
    assert add(-1, -2) == -3


def test_divide_normal():
    assert divide(10.0, 2.0) == 5.0


def test_divide_by_zero_raises():
    with pytest.raises(ValueError):
        divide(5.0, 0)
