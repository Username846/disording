extends TestCase


func test_add_days() -> void:
	check_eq(IsoDate.add_days("2026-12-31", 1), "2027-01-01")
	check_eq(IsoDate.add_days("2028-02-28", 1), "2028-02-29")
	check_eq(IsoDate.add_days("2026-03-01", -1), "2026-02-28")
	check_eq(IsoDate.days_between("2026-11-01", "2026-12-01"), 30)


func test_validation_and_order() -> void:
	check(IsoDate.is_valid("2026-11-01"), "valid date")
	check(not IsoDate.is_valid("2026-13-01"), "bad month")
	check(not IsoDate.is_valid("hello"), "garbage")
	check_eq(IsoDate.later("2026-11-02", "2026-11-01"), "2026-11-02")
	check_eq(IsoDate.later("", "2026-11-01"), "2026-11-01")
