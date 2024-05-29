# frozen_string_literal: true

require "base64"

RSpec.describe Stability do
  it "has a version number" do
    expect(Stability::VERSION).not_to be nil
  end

  describe Stability::Client do
    let(:client) do
      Stability::Client.new(api_key: ENV["API_KEY"]) do |config|
        config.faraday do |f|
          f.response :logger, ::Logger.new($stdout), { headers: true, bodies: true, errors: true } do |logger|
            logger.filter(/(Bearer) (\S+)/, '\1[REDACTED]')
          end
        end
      end
    end

    describe "#initialize" do
      it "yields the configuration" do
        expect { |b| Stability::Client.new(&b) }.to yield_with_args(Stability.configuration)
      end
    end

    describe "#generate_core" do
      let(:prompt) { "A beautiful sunset over the city" }

      it "sends a POST request to the generate endpoint with the correct parameters and generates an image" do
        expect(client).to receive(:multipart_post).with(
          path: "/stable-image/generate/core",
          headers: { "Accept" => "application/json" },
          parameters: { prompt: }
        ).and_call_original

        response = client.generate_core(prompt, json: true)
        expect(response).to be_a(Hash)
        expect(response).to have_key("image")
        expect(response["image"]).to be_a(String)
        expect(response["finish_reason"]).to eq("SUCCESS")

        unless ENV["CI"]
          # Decode the base64 image and save it to a specific file in /tmp
          image_data = Base64.decode64(response["image"])
          file_path = "/tmp/core_generated_image.png"
          File.open(file_path, "wb") do |file|
            file.write(image_data)
          end

          # Open the image file
          system("open", file_path)
        end
      end
    end

    describe "#generate_sd3" do
      let(:prompt) { "A futuristic cityscape at night" }

      it "sends a POST request to the generate endpoint with the correct parameters and generates an image" do
        expect(client).to receive(:multipart_post).with(
          path: "/stable-image/generate/sd3",
          headers: { "Accept" => "application/json" },
          parameters: { prompt: }
        ).and_call_original

        response = client.generate_sd3(prompt, json: true)
        expect(response).to be_a(Hash)
        expect(response).to have_key("image")
        expect(response["image"]).to be_a(String)
        expect(response["finish_reason"]).to eq("SUCCESS")

        # Decode the base64 image and save it to a specific file in /tmp
        unless ENV["CI"]
          image_data = Base64.decode64(response["image"])
          file_path = "/tmp/sd3_generated_image.png"
          File.open(file_path, "wb") do |file|
            file.write(image_data)
          end

          # Open the image file
          system("open", file_path)
        end
      end

      context "when mode is image-to-image" do
        let(:image_path) { "spec/fixtures/files/sample_image.jpg" }
        let(:image_file) { File.open(image_path, "rb") }
        let(:strength) { 0.75 }

        it "sends a POST request to the generate endpoint with the correct parameters and generates an image" do
          expect(client).to receive(:multipart_post).with(
            path: "/stable-image/generate/sd3",
            headers: { "Accept" => "application/json" },
            parameters: { prompt:, model: "sd3-turbo", mode: "image-to-image", image: image_file, strength: }
          ).and_call_original

          response = client.generate_sd3(prompt, options: { model: "sd3-turbo", mode: "image-to-image", image: image_file, strength: }, json: true)
          expect(response).to be_a(Hash)
          expect(response).to have_key("image")
          expect(response["image"]).to be_a(String)
          expect(response["finish_reason"]).to eq("SUCCESS")

          # Decode the base64 image and save it to a specific file in /tmp
          unless ENV["CI"]
            image_data = Base64.decode64(response["image"])
            file_path = "/tmp/sd3_generated_image-to-image.png"
            File.open(file_path, "wb") do |file|
              file.write(image_data)
            end

            # Open the image file
            system("open", file_path)
          end
        end
      end
    end
  end
end
