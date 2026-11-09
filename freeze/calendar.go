package freeze

import (
	"bufio"
	"bytes"
	"fmt"
	"strings"
	"time"
)

// Calendar is the frozen days: verified dates of data/holidays.tt, each with
// its festival key (festival.sabantuy, ...).
type Calendar map[string]string // YYYY-MM-DD -> festival key

// ParseHolidays reads data/holidays.tt. Only full dates count: a month and a
// day without a year was verified for some year, not for every one.
func ParseHolidays(raw []byte) (Calendar, error) {
	c := Calendar{}
	sc := bufio.NewScanner(bytes.NewReader(raw))
	for n := 1; sc.Scan(); n++ {
		line := sc.Text()
		if i := strings.Index(line, "#"); i >= 0 {
			line = line[:i]
		}
		f := strings.Fields(line)
		if len(f) == 0 {
			continue
		}
		if len(f) < 2 {
			return nil, fmt.Errorf("line %d: want \"YYYY-MM-DD festival.key\"", n)
		}
		if _, err := time.Parse(time.DateOnly, f[0]); err != nil {
			continue // not a verified, dated entry
		}
		c[f[0]] = f[1]
	}
	return c, sc.Err()
}

// On says which holiday the day of t is, in loc.
func (c Calendar) On(t time.Time, loc *time.Location) (key string, ok bool) {
	key, ok = c[t.In(loc).Format(time.DateOnly)]
	return key, ok
}

// Verified reports whether data/holidays.tt has dates for the year of t in
// loc. Without them no day of that year is a holiday, whatever the date.
func (c Calendar) Verified(t time.Time, loc *time.Location) bool {
	year := t.In(loc).Format("2006-")
	for day := range c {
		if strings.HasPrefix(day, year) {
			return true
		}
	}
	return false
}

// HolidayName is the catalog key of a festival's name: festival.sabantuy
// -> holiday.sabantuy.
func HolidayName(festival string) string {
	return "holiday." + strings.TrimPrefix(festival, "festival.")
}

// FixedDay is a clock stopped at noon of day (YYYY-MM-DD) in loc: tests
// pretend it is a holiday with it. Empty day is the real clock.
func FixedDay(day string, loc *time.Location) (func() time.Time, error) {
	if day == "" {
		return time.Now, nil
	}
	d, err := time.ParseInLocation(time.DateOnly, day, loc)
	if err != nil {
		return nil, fmt.Errorf("want YYYY-MM-DD: %w", err)
	}
	noon := d.Add(12 * time.Hour)
	return func() time.Time { return noon }, nil
}
