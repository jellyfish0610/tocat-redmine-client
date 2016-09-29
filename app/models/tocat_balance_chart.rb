class TocatBalanceChart
  TRANSACTIONS_LIMIT = 9999999

  attr_reader :tocat_user
  attr_reader :period

  def initialize(tocat_user, period_identifier)
    @tocat_user = tocat_user
    @period = PresetPeriods.period(period_identifier)
  end

  def chart_data
    balance_chart = { balance: [], timeline: [] }
    balance_transactions_by_date = user_balance_transactions_sum_by_date(tocat_user, period)
    balance = 0

    period.each do |date|
      balance += balance_transactions_by_date.fetch(date.to_s, 0).round(2)

      balance_chart[:balance] << balance
      balance_chart[:timeline] << date
    end
    balance_chart
  end

  def current_period_delta
    @current_period_delta ||= balance_period_transactions(tocat_user, period).sum { |r| r.total.to_i}
  end

  def current_delta
    @current_delta ||= balance_transactions(tocat_user, period).sum { |r| r.total.to_i}
  end

  private

  def user_balance_transactions_sum_by_date(tocat_user, period)
    user_balance_transactions(tocat_user, period)
      .group_by { |t| t.date.to_date.to_s }
      .each_with_object({}) do |(date, date_transactions), transactions_sums|
      transactions_sums[date] = date_transactions.sum { |r| r.total.to_i }
    end
  end

  def user_balance_transactions(tocat_user, period)
    search = [
      'account = balance',
      "created_at >= #{period.begin.strftime('%Y-%m-%d')}",
      "created_at <= #{period.end.strftime('%Y-%m-%d')}"
    ].join(' ')
    TocatTransaction.find(:all, params: { user: tocat_user.accounts.balance.id, search: search, limit: TRANSACTIONS_LIMIT })
  end

  def balance_transactions(tocat_user, period)
    search = [
      "created_at >= #{period.begin.strftime('%Y-%m-%d')}",
      'account = balance'
    ].join(' ')
    TocatTransaction.find(:all, params: { user: tocat_user.accounts.balance.id, search: search, limit: TRANSACTIONS_LIMIT })
  end

  def balance_period_transactions(tocat_user, period)
    search = [
      "created_at >= #{period.begin.strftime('%Y-%m-%d')}",
      "created_at <= #{period.end.strftime('%Y-%m-%d')}",
      'account = balance'
    ].join(' ')
    TocatTransaction.find(:all, params: { user: tocat_user.accounts.balance.id, search: search, limit: TRANSACTIONS_LIMIT })
  end

  class PresetPeriods
    DEFAULT_PERIOD = ->(date) { date_quarter_period(date) }
    PRESET_PERIODS = {
      'this_quarter' => ->(date) { date_quarter_period(date) },
      'previous_quarter' => ->(date) { date_quarter_period(date - 3.months) },
      'two_weeks' => ->(date) { Range.new(date - 2.weeks, date) },
      'one_week' => ->(date) { Range.new(date - 1.weeks, date) }
    }

    class << self
      def period(period_identifier)
        PRESET_PERIODS.fetch(period_identifier, DEFAULT_PERIOD).call(Time.zone.today)
      end

      private

      def date_quarter_period(date)
        Range.new(date.at_beginning_of_quarter, date.at_end_of_quarter)
      end
    end
  end
end
