# Stability

Provides easy access to the Stable Image REST API provided by [stability.ai](https://platform.stability.ai/docs/api-reference).
This library is maintained by Obie Fernandez and the team at [Olympia](https://olympia.chat), the world's premier Ruby on Rails-based AI platform,
offering AI-powered teams for solopreneurs and small businesses. You can support this project by being a customer of Olympia, or buying Obie's book
[Patterns of Application Development Using AI](https://leanpub.com/patterns-of-application-development-using-ai)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add stability

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install stability

## Usage

First, configure the `Stability` client with your API key. You can set the API key directly or use environment variables.

```ruby
require 'stability'

Stability.configure do |config|
  config.api_key = ENV['STABILITY_API_KEY'] # or set directly: config.api_key = 'your_api_key'
end
```

### Text-to-Image Generation

To generate an image from a text prompt, use the `generate_core` method. This method allows you to specify various options such as aspect ratio, negative prompts, seed, style presets, and output format.

```ruby
client = Stability::Client.new

prompt = "A beautiful sunset over the city"
options = {
  aspect_ratio: "16:9",
  negative_prompt: "No people",
  seed: 12345,
  style_preset: "photographic",
  output_format: "png"
}

response = client.generate_core(prompt, options: options, json: true)

if response["finish_reason"] == "SUCCESS"
  image_data = Base64.decode64(response["image"])
  File.open("/tmp/generated_image.png", "wb") { |file| file.write(image_data) }
  puts "Image generated successfully!"
else
  puts "Failed to generate image: #{response['error']['message']}"
end
```

### Image-to-Image Generation

To generate an image from an existing image and a text prompt, use the `generate_sd3` method with the `image-to-image` mode. This method requires additional parameters such as the input image and the strength of the transformation.

```ruby
client = Stability::Client.new

prompt = "A futuristic cityscape at night"
image_path = "path/to/your/input_image.png"
image_file = File.open(image_path, "rb")
strength = 0.75

options = {
  mode: "image-to-image",
  image: image_file,
  strength: strength,
  negative_prompt: "No people",
  model: "sd3",
  seed: 12345,
  output_format: "png"
}

response = client.generate_sd3(prompt, options: options, json: true)

if response["finish_reason"] == "SUCCESS"
  image_data = Base64.decode64(response["image"])
  File.open("/tmp/generated_image.png", "wb") { |file| file.write(image_data) }
  puts "Image generated successfully!"
else
  puts "Failed to generate image: #{response['error']['message']}"
end
```

Note that a full guide to image generation models and their parameters is available [here](https://platform.stability.ai/docs/api-reference#tag/Generate).

### Handling Errors

Both methods raise a `ServerError` if the response is empty or contains an error message. Ensure you handle these exceptions appropriately in your application.

```ruby
begin
  response = client.generate_core(prompt, options: options, json: true)
  # Process response
rescue Stability::ServerError => e
  puts "An error occurred: #{e.message}"
end
```

### Rate Limiting

The Stability API is rate-limited to 150 requests every 10 seconds. If you exceed this limit, you will receive a 429 response and be timed out for 60 seconds. Ensure your application handles rate limiting appropriately.

```ruby
begin
  response = client.generate_core(prompt, options: options, json: true)
  # Process response
rescue Stability::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
  sleep(60) # Wait for the timeout period before retrying
  retry
end
```

These instructions should help users get started with the Stability SDK and understand how to use its core functionalities.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/OlympiaAI/stability. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/OlympiaAI/stability/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in our codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/OlympiaAI/stability/blob/main/CODE_OF_CONDUCT.md).
