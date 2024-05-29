# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"

require_relative "http"

module Stability
  class ServerError < StandardError; end

  class Client
    include Stability::HTTP

    # Initializes the client with optional configurations.
    def initialize(api_key: nil, request_timeout: nil, uri_base: nil, extra_headers: {})
      Stability.configuration.api_key = api_key if api_key
      Stability.configuration.request_timeout = request_timeout if request_timeout
      Stability.configuration.uri_base = uri_base if uri_base
      Stability.configuration.extra_headers = extra_headers if extra_headers.any?
      yield(Stability.configuration) if block_given?
    end

    # Performs a text-to-image generation request to the Stability API using Stable Image Core.
    #
    # @param prompt [String] Descriptive prompt for the desired output image. Elements, colors, and subjects should be well-defined
    #                        for optimal results. Use the format (word:weight) to control the weight of specific words, e.g.,
    #                        "The sky was a crisp (blue:0.3) and (green:0.8)" indicates a sky more green than blue.
    #
    # @param options [Hash] Additional options for the request:
    #
    #   - aspect_ratio [String] Specifies the aspect ratio of the generated image.
    #     Options: "16:9", "1:1" (default), "21:9", "2:3", "3:2", "4:5", "5:4", "9:16", "9:21"
    #
    #   - negative_prompt [String] Describes elements to be excluded from the image. Max 10000 characters.
    #
    #   - seed [Integer] Controls the randomness of generation, where 0 uses a random seed. Range: 0 (default) to 4294967294
    #
    #   - style_preset [String] Guides the image model towards a particular visual style.
    #     Options: "3d-model", "analog-film", "anime", "cinematic", "comic-book", "digital-art", "enhance", "fantasy-art",
    #              "isometric", "line-art", "low-poly", "modeling-compound", "neon-punk", "origami", "photographic",
    #              "pixel-art", "tile-texture"
    #
    #   - output_format [String] Specifies the format of the generated image. Options: "jpeg", "png" (default), "webp"
    #
    # @param json [Boolean] Specifies whether to return the response as a JSON object containing a base64 encoded image or as
    #                       image bytes directly. Default is false (image bytes directly).
    #
    def generate_core(prompt, options: {}, json: false)
      headers = { "Accept" => json ? "application/json" : "image/*" }
      parameters = { prompt: }.merge(options)
      multipart_post(path: "/stable-image/generate/core", headers:, parameters:).tap do |response|
        raise ServerError, "Empty response from Stability. Might be worth retrying once or twice." if response.blank?
        raise ServerError, response.dig("error", "message") if response.dig("error", "message").present?
      end.with_indifferent_access
    end

    # Performs a text-to-image or image-to-image generation request to the Stability API using Stable Diffusion 3.
    #
    # @param prompt [String] Descriptive prompt for the desired output image. Elements, colors, and subjects should be well-defined
    #                        for optimal results. Use the format (word:weight) to control the weight of specific words, e.g.,
    #                        "The sky was a crisp (blue:0.3) and (green:0.8)" indicates a sky more green than blue.
    #
    # @param options [Hash] Additional options for the request:
    #
    #   - aspect_ratio [String] Specifies the aspect ratio of the generated image.
    #     Options: "16:9", "1:1" (default), "21:9", "2:3", "3:2", "4:5", "5:4", "9:16", "9:21"
    #
    #   - mode [String] Controls whether this is a text-to-image or image-to-image generation.
    #     Options: "text-to-image" (default), "image-to-image"
    #
    #   - image [File] Required if mode is "image-to-image". The input image file.
    #
    #   - strength [Float] Required if mode is "image-to-image". Controls the strength of the transformation.
    #
    #   - negative_prompt [String] Describes elements to be excluded from the image. Max 10000 characters.
    #
    #   - model [String] Specifies the model to use for generation.
    #     Options: "sd3" (default), "sd3-turbo"
    #
    #   - seed [Integer] Controls the randomness of generation, where 0 uses a random seed. Range: 0 (default) to 4294967294
    #
    #   - output_format [String] Specifies the format of the generated image. Options: "jpeg", "png" (default)
    #
    # @param json [Boolean] Specifies whether to return the response as a JSON object containing a base64 encoded image or as
    #                       image bytes directly. Default is false (image bytes directly).
    #
    def generate_sd3(prompt, options: {}, json: false)
      headers = { "Accept" => json ? "application/json" : "image/*" }
      parameters = { prompt: }.merge(options)

      # Ensure required parameters for image-to-image mode
      if parameters[:mode] == "image-to-image"
        raise ArgumentError, "image is required for image-to-image mode" unless parameters[:image]
        raise ArgumentError, "strength is required for image-to-image mode" unless parameters[:strength]
      end

      multipart_post(path: "/stable-image/generate/sd3", headers:, parameters:).tap do |response|
        raise ServerError, "Empty response from Stability. Might be worth retrying once or twice." if response.blank?
        raise ServerError, response.dig("error", "message") if response.dig("error", "message").present?
      end.with_indifferent_access
    end
  end
end
