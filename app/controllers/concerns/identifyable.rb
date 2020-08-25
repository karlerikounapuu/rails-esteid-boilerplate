module Identifyable
  extend ActiveSupport::Concern

  included do
    validate :validate_personal_id
  end

  def id_verified?
    personal_id.size == 11 && personal_id[10].chr.to_i == control_personal_id && birth_date.is_a?(Date)
  end

  def validate_personal_id
    errors.add(:personal_id, :invalid) unless id_verified?
  end

  private

  def control_personal_id
    scales1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 1]
    checknum = scales1.each_with_index.map { |scale, i| personal_id[i].chr.to_i * scale }.inject(0, :+) % 11
    return checknum unless checknum == 10

    scales2 = [3, 4, 5, 6, 7, 8, 9, 1, 2, 3]
    checknum = scales2.each_with_index.map { |scale, i| personal_id[i].chr.to_i * scale }.inject(0, :+) % 11
    checknum == 10 ? 0 : checknum
  end

  def birth_date
    year = century + personal_id[1..2].to_i
    month = personal_id[3..4].to_i
    day = personal_id[5..6].to_i
    Date.valid_date?(year, month, day) ? Date.strptime("#{year}-#{month}-#{day}", '%Y-%m-%d') : nil
  end

  def century
    case personal_id[0].chr.to_i
    when 1..2 then 1800
    when 3..4 then 1900
    else
      2000
    end
  end
end
