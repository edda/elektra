# Surrounds all js files inside a plugin with a closure.
class AssetsClosurePreprocessor < Sprockets::Processor
  def evaluate(context, locals)

    match = /\/plugins\/(.+)\/app\/assets/.match(context.pathname.to_s)
    
    # is current js file from a plugin 
    if match
      # get the plugin name
      plugin_name = match[1]
      coffeescript = context.pathname.to_s.include?('.coffee')

      data.replace "window.#{plugin_name} = window.#{plugin_name} || {};\n\n#{data}"
      data.replace "(function(){\n  #{data}\n}).call(this);\n" unless coffeescript
    end
    data
  end
end