#!/bin/bash
set -e

# parse-period.sh
# Parses time period specifications and outputs start/end timestamps

echo "::group::Parsing time period"

# If start_date and end_date are provided, use those
if [[ -n "$INPUT_START_DATE" && -n "$INPUT_END_DATE" ]]; then
  echo "Using explicit date range: $INPUT_START_DATE to $INPUT_END_DATE"

  # Validate date format (YYYY-MM-DD)
  if ! [[ "$INPUT_START_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "::error::Invalid start_date format. Expected YYYY-MM-DD, got: $INPUT_START_DATE"
    exit 1
  fi

  if ! [[ "$INPUT_END_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "::error::Invalid end_date format. Expected YYYY-MM-DD, got: $INPUT_END_DATE"
    exit 1
  fi

  START_DATE="$INPUT_START_DATE"
  END_DATE="$INPUT_END_DATE"

  # Convert to timestamps
  START_TIMESTAMP="${START_DATE}T00:00:00Z"
  END_TIMESTAMP="${END_DATE}T23:59:59Z"

  echo "START_DATE=$START_DATE" >> "$GITHUB_OUTPUT"
  echo "END_DATE=$END_DATE" >> "$GITHUB_OUTPUT"
  echo "START_TIMESTAMP=$START_TIMESTAMP" >> "$GITHUB_OUTPUT"
  echo "END_TIMESTAMP=$END_TIMESTAMP" >> "$GITHUB_OUTPUT"

  echo "Period: $START_TIMESTAMP to $END_TIMESTAMP"
  echo "::endgroup::"
  exit 0
fi

# Otherwise, parse the period parameter
PERIOD="${INPUT_PERIOD:-last-month}"
echo "Parsing period: $PERIOD"

# Get current date for relative calculations
CURRENT_DATE=$(date -u +%Y-%m-%d)

case "$PERIOD" in
  last-7-days)
    START_DATE=$(date -u -d "$CURRENT_DATE - 7 days" +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d)
    END_DATE="$CURRENT_DATE"
    ;;

  last-14-days)
    START_DATE=$(date -u -d "$CURRENT_DATE - 14 days" +%Y-%m-%d 2>/dev/null || date -u -v-14d +%Y-%m-%d)
    END_DATE="$CURRENT_DATE"
    ;;

  last-30-days)
    START_DATE=$(date -u -d "$CURRENT_DATE - 30 days" +%Y-%m-%d 2>/dev/null || date -u -v-30d +%Y-%m-%d)
    END_DATE="$CURRENT_DATE"
    ;;

  last-month)
    # Get first day of last month
    START_DATE=$(date -u -d "$(date +%Y-%m-01) - 1 month" +%Y-%m-01 2>/dev/null || date -u -v1d -v-1m +%Y-%m-01)
    # Get last day of last month (first day of current month - 1 day)
    END_DATE=$(date -u -d "$(date +%Y-%m-01) - 1 day" +%Y-%m-%d 2>/dev/null || date -u -v1d -v-1d +%Y-%m-%d)
    ;;

  last-quarter)
    # Determine current quarter
    CURRENT_MONTH=$(date -u +%m)
    CURRENT_YEAR=$(date -u +%Y)

    if [[ $CURRENT_MONTH -ge 1 && $CURRENT_MONTH -le 3 ]]; then
      # Q1 -> Last quarter is Q4 of previous year
      START_DATE="$((CURRENT_YEAR - 1))-10-01"
      END_DATE="$((CURRENT_YEAR - 1))-12-31"
    elif [[ $CURRENT_MONTH -ge 4 && $CURRENT_MONTH -le 6 ]]; then
      # Q2 -> Last quarter is Q1
      START_DATE="${CURRENT_YEAR}-01-01"
      END_DATE="${CURRENT_YEAR}-03-31"
    elif [[ $CURRENT_MONTH -ge 7 && $CURRENT_MONTH -le 9 ]]; then
      # Q3 -> Last quarter is Q2
      START_DATE="${CURRENT_YEAR}-04-01"
      END_DATE="${CURRENT_YEAR}-06-30"
    else
      # Q4 -> Last quarter is Q3
      START_DATE="${CURRENT_YEAR}-07-01"
      END_DATE="${CURRENT_YEAR}-09-30"
    fi
    ;;

  last-year)
    CURRENT_YEAR=$(date -u +%Y)
    START_DATE="$((CURRENT_YEAR - 1))-01-01"
    END_DATE="$((CURRENT_YEAR - 1))-12-31"
    ;;

  [0-9][0-9][0-9][0-9]-[0-9][0-9])
    # Format: YYYY-MM (specific month)
    YEAR=$(echo "$PERIOD" | cut -d'-' -f1)
    MONTH=$(echo "$PERIOD" | cut -d'-' -f2)

    # First day of month
    START_DATE="${YEAR}-${MONTH}-01"

    # Last day of month
    if [[ $MONTH == "12" ]]; then
      NEXT_YEAR=$((YEAR + 1))
      NEXT_MONTH="01"
    else
      NEXT_YEAR=$YEAR
      NEXT_MONTH=$(printf "%02d" $((10#$MONTH + 1)))
    fi

    # Last day is first day of next month minus 1 day
    END_DATE=$(date -u -d "${NEXT_YEAR}-${NEXT_MONTH}-01 - 1 day" +%Y-%m-%d 2>/dev/null || date -u -j -v1d -v+1m -v-1d -f "%Y-%m-%d" "${YEAR}-${MONTH}-01" +%Y-%m-%d)
    ;;

  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]..[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    # Format: YYYY-MM-DD..YYYY-MM-DD (explicit range)
    START_DATE=$(echo "$PERIOD" | cut -d'.' -f1)
    END_DATE=$(echo "$PERIOD" | cut -d'.' -f3)
    ;;

  *)
    echo "::error::Invalid period format: $PERIOD"
    echo "::error::Valid formats: last-7-days, last-14-days, last-30-days, last-month, last-quarter, last-year, YYYY-MM, YYYY-MM-DD..YYYY-MM-DD"
    exit 1
    ;;
esac

# Convert to ISO 8601 timestamps
START_TIMESTAMP="${START_DATE}T00:00:00Z"
END_TIMESTAMP="${END_DATE}T23:59:59Z"

# Output to GitHub Actions
echo "START_DATE=$START_DATE" >> "$GITHUB_OUTPUT"
echo "END_DATE=$END_DATE" >> "$GITHUB_OUTPUT"
echo "START_TIMESTAMP=$START_TIMESTAMP" >> "$GITHUB_OUTPUT"
echo "END_TIMESTAMP=$END_TIMESTAMP" >> "$GITHUB_OUTPUT"

# Also output a human-readable period description
if [[ "$PERIOD" == "last-month" ]]; then
  MONTH_NAME=$(date -d "$START_DATE" +%B 2>/dev/null || date -j -f "%Y-%m-%d" "$START_DATE" +%B)
  YEAR=$(date -d "$START_DATE" +%Y 2>/dev/null || date -j -f "%Y-%m-%d" "$START_DATE" +%Y)
  PERIOD_DESCRIPTION="$MONTH_NAME $YEAR"
else
  PERIOD_DESCRIPTION="$START_DATE to $END_DATE"
fi

echo "PERIOD_DESCRIPTION=$PERIOD_DESCRIPTION" >> "$GITHUB_OUTPUT"

echo "✓ Period parsed successfully"
echo "  Start: $START_TIMESTAMP"
echo "  End: $END_TIMESTAMP"
echo "  Description: $PERIOD_DESCRIPTION"

echo "::endgroup::"
