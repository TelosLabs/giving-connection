# frozen_string_literal: true

module SmartMatchHelper
  def segment_fill_pct(section_steps, seg, current_section_number, step)
    return 0 if section_steps.empty? || seg > current_section_number
    return 100 if seg < current_section_number

    (section_steps.count { |s| s <= step }.to_f / section_steps.size * 100).round
  end

  def segment_prev_fill_pct(section_steps, seg, current_section_number, step)
    return segment_fill_pct(section_steps, seg, current_section_number, step) unless seg == current_section_number

    (section_steps.count { |s| s < step }.to_f / section_steps.size * 100).round
  end
end
