from app import get_labels


def test_get_labels_defaults_to_korean() -> None:
    labels = get_labels("ko")
    assert labels["status_loading"] == "로딩 중"
