module BlockHelper

  def block_to_partial(partial_name, options = {}, &block)
    options.merge!(:body => capture(&block))
    concat(render(:partial => partial_name, :locals => options), block.binding)
  end

  def exemplo(options = {})
    block_to_partial("shared/rounded_box", options, &block)
  end

end