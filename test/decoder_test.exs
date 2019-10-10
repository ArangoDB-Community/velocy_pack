defmodule VelocyPack.DecoderTest do
  use ExUnit.Case, async: true

  import VelocyPack

  describe "parse" do
    test "empty array" do
      assert decode!(<<0x01>>) == []
    end

    test "empty object" do
      assert decode!(<<0x0A>>) == %{}
    end

    test "illegal" do
      assert decode!(<<0x17>>) == :illegal
    end

    test "nil" do
      assert decode!(<<0x18>>) == nil
    end

    test "boolean" do
      assert decode!(<<0x19>>) == false
      assert decode!(<<0x1A>>) == true
    end

    test "double" do
      assert decode!(<<0x1B, 0x66, 0x66, 0x66, 0x66, 0x66, 0xB6, 0x60, 0x40>>) == 133.7
      assert decode!(<<0x1B, 0x66, 0x66, 0x66, 0x66, 0x66, 0xB6, 0x60, 0xC0>>) == -133.7
    end

    test "date" do
      assert decode!(<<0x1C, 0, 83, 115, 5, -114, 0, 0, 0>>) ==
               DateTime.from_unix!(609_976_800_000, :millisecond)
    end

    test "min/max key" do
      assert decode!(<<0x1E>>) == :min_key
      assert decode!(<<0x1F>>) == :max_key
    end

    test "small int" do
      assert decode!(<<0x30>>) == 0
      assert decode!(<<0x31>>) == 1
      assert decode!(<<0x32>>) == 2
      assert decode!(<<0x33>>) == 3
      assert decode!(<<0x34>>) == 4
      assert decode!(<<0x35>>) == 5
      assert decode!(<<0x36>>) == 6
      assert decode!(<<0x37>>) == 7
      assert decode!(<<0x38>>) == 8
      assert decode!(<<0x39>>) == 9
      assert decode!(<<0x3A>>) == -6
      assert decode!(<<0x3B>>) == -5
      assert decode!(<<0x3C>>) == -4
      assert decode!(<<0x3D>>) == -3
      assert decode!(<<0x3E>>) == -2
      assert decode!(<<0x3F>>) == -1
    end

    test "int" do
      assert decode!(<<0x20, 0xFF>>) == -1
      assert decode!(<<0x20, 0x7F>>) == 127
      assert decode!(<<0x20, 0x80>>) == -128
      assert decode!(<<0x21, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x22, 0xFF, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x23, 0xFF, 0xFF, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x24, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x25, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x26, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == -1
      assert decode!(<<0x27, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == -1

      assert decode!(<<0x27, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>) ==
               9_223_372_036_854_775_807

      assert decode!(<<0x28, 0xFF>>) == 255
      assert decode!(<<0x29, 0xFF, 0xFF>>) == 65535
      assert decode!(<<0x2A, 0xFF, 0xFF, 0xFF>>) == 16_777_215
      assert decode!(<<0x2B, 0xFF, 0xFF, 0xFF, 0xFF>>) == 4_294_967_295
      assert decode!(<<0x2C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == 1_099_511_627_775
      assert decode!(<<0x2D, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == 281_474_976_710_655
      assert decode!(<<0x2E, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) == 72_057_594_037_927_935

      assert decode!(<<0x2F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) ==
               18_446_744_073_709_551_615
    end

    test "short string" do
      assert decode!(<<0x4B, 72, 97, 108, 108, 111, 32, 87, 101, 108, 116, 33>>) == "Hallo Welt!"

      assert decode!(<<0x4C, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33>>) ==
               "Hello World!"
    end

    test "string" do
      expected =
        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. " <>
          "Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. " <>
          "Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. " <>
          "Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, " <>
          "venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus. " <>
          "Vivamus elementum semper nisi. Aenean vulputate eleifend tellus."

      data =
        <<0xBF, 0x37, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4C, 0x6F, 0x72, 0x65, 0x6D,
          0x20, 0x69, 0x70, 0x73, 0x75, 0x6D, 0x20, 0x64, 0x6F, 0x6C, 0x6F, 0x72, 0x20, 0x73,
          0x69, 0x74, 0x20, 0x61, 0x6D, 0x65, 0x74, 0x2C, 0x20, 0x63, 0x6F, 0x6E, 0x73, 0x65,
          0x63, 0x74, 0x65, 0x74, 0x75, 0x65, 0x72, 0x20, 0x61, 0x64, 0x69, 0x70, 0x69, 0x73,
          0x63, 0x69, 0x6E, 0x67, 0x20, 0x65, 0x6C, 0x69, 0x74, 0x2E, 0x20, 0x41, 0x65, 0x6E,
          0x65, 0x61, 0x6E, 0x20, 0x63, 0x6F, 0x6D, 0x6D, 0x6F, 0x64, 0x6F, 0x20, 0x6C, 0x69,
          0x67, 0x75, 0x6C, 0x61, 0x20, 0x65, 0x67, 0x65, 0x74, 0x20, 0x64, 0x6F, 0x6C, 0x6F,
          0x72, 0x2E, 0x20, 0x41, 0x65, 0x6E, 0x65, 0x61, 0x6E, 0x20, 0x6D, 0x61, 0x73, 0x73,
          0x61, 0x2E, 0x20, 0x43, 0x75, 0x6D, 0x20, 0x73, 0x6F, 0x63, 0x69, 0x69, 0x73, 0x20,
          0x6E, 0x61, 0x74, 0x6F, 0x71, 0x75, 0x65, 0x20, 0x70, 0x65, 0x6E, 0x61, 0x74, 0x69,
          0x62, 0x75, 0x73, 0x20, 0x65, 0x74, 0x20, 0x6D, 0x61, 0x67, 0x6E, 0x69, 0x73, 0x20,
          0x64, 0x69, 0x73, 0x20, 0x70, 0x61, 0x72, 0x74, 0x75, 0x72, 0x69, 0x65, 0x6E, 0x74,
          0x20, 0x6D, 0x6F, 0x6E, 0x74, 0x65, 0x73, 0x2C, 0x20, 0x6E, 0x61, 0x73, 0x63, 0x65,
          0x74, 0x75, 0x72, 0x20, 0x72, 0x69, 0x64, 0x69, 0x63, 0x75, 0x6C, 0x75, 0x73, 0x20,
          0x6D, 0x75, 0x73, 0x2E, 0x20, 0x44, 0x6F, 0x6E, 0x65, 0x63, 0x20, 0x71, 0x75, 0x61,
          0x6D, 0x20, 0x66, 0x65, 0x6C, 0x69, 0x73, 0x2C, 0x20, 0x75, 0x6C, 0x74, 0x72, 0x69,
          0x63, 0x69, 0x65, 0x73, 0x20, 0x6E, 0x65, 0x63, 0x2C, 0x20, 0x70, 0x65, 0x6C, 0x6C,
          0x65, 0x6E, 0x74, 0x65, 0x73, 0x71, 0x75, 0x65, 0x20, 0x65, 0x75, 0x2C, 0x20, 0x70,
          0x72, 0x65, 0x74, 0x69, 0x75, 0x6D, 0x20, 0x71, 0x75, 0x69, 0x73, 0x2C, 0x20, 0x73,
          0x65, 0x6D, 0x2E, 0x20, 0x4E, 0x75, 0x6C, 0x6C, 0x61, 0x20, 0x63, 0x6F, 0x6E, 0x73,
          0x65, 0x71, 0x75, 0x61, 0x74, 0x20, 0x6D, 0x61, 0x73, 0x73, 0x61, 0x20, 0x71, 0x75,
          0x69, 0x73, 0x20, 0x65, 0x6E, 0x69, 0x6D, 0x2E, 0x20, 0x44, 0x6F, 0x6E, 0x65, 0x63,
          0x20, 0x70, 0x65, 0x64, 0x65, 0x20, 0x6A, 0x75, 0x73, 0x74, 0x6F, 0x2C, 0x20, 0x66,
          0x72, 0x69, 0x6E, 0x67, 0x69, 0x6C, 0x6C, 0x61, 0x20, 0x76, 0x65, 0x6C, 0x2C, 0x20,
          0x61, 0x6C, 0x69, 0x71, 0x75, 0x65, 0x74, 0x20, 0x6E, 0x65, 0x63, 0x2C, 0x20, 0x76,
          0x75, 0x6C, 0x70, 0x75, 0x74, 0x61, 0x74, 0x65, 0x20, 0x65, 0x67, 0x65, 0x74, 0x2C,
          0x20, 0x61, 0x72, 0x63, 0x75, 0x2E, 0x20, 0x49, 0x6E, 0x20, 0x65, 0x6E, 0x69, 0x6D,
          0x20, 0x6A, 0x75, 0x73, 0x74, 0x6F, 0x2C, 0x20, 0x72, 0x68, 0x6F, 0x6E, 0x63, 0x75,
          0x73, 0x20, 0x75, 0x74, 0x2C, 0x20, 0x69, 0x6D, 0x70, 0x65, 0x72, 0x64, 0x69, 0x65,
          0x74, 0x20, 0x61, 0x2C, 0x20, 0x76, 0x65, 0x6E, 0x65, 0x6E, 0x61, 0x74, 0x69, 0x73,
          0x20, 0x76, 0x69, 0x74, 0x61, 0x65, 0x2C, 0x20, 0x6A, 0x75, 0x73, 0x74, 0x6F, 0x2E,
          0x20, 0x4E, 0x75, 0x6C, 0x6C, 0x61, 0x6D, 0x20, 0x64, 0x69, 0x63, 0x74, 0x75, 0x6D,
          0x20, 0x66, 0x65, 0x6C, 0x69, 0x73, 0x20, 0x65, 0x75, 0x20, 0x70, 0x65, 0x64, 0x65,
          0x20, 0x6D, 0x6F, 0x6C, 0x6C, 0x69, 0x73, 0x20, 0x70, 0x72, 0x65, 0x74, 0x69, 0x75,
          0x6D, 0x2E, 0x20, 0x49, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x20, 0x74, 0x69, 0x6E,
          0x63, 0x69, 0x64, 0x75, 0x6E, 0x74, 0x2E, 0x20, 0x43, 0x72, 0x61, 0x73, 0x20, 0x64,
          0x61, 0x70, 0x69, 0x62, 0x75, 0x73, 0x2E, 0x20, 0x56, 0x69, 0x76, 0x61, 0x6D, 0x75,
          0x73, 0x20, 0x65, 0x6C, 0x65, 0x6D, 0x65, 0x6E, 0x74, 0x75, 0x6D, 0x20, 0x73, 0x65,
          0x6D, 0x70, 0x65, 0x72, 0x20, 0x6E, 0x69, 0x73, 0x69, 0x2E, 0x20, 0x41, 0x65, 0x6E,
          0x65, 0x61, 0x6E, 0x20, 0x76, 0x75, 0x6C, 0x70, 0x75, 0x74, 0x61, 0x74, 0x65, 0x20,
          0x65, 0x6C, 0x65, 0x69, 0x66, 0x65, 0x6E, 0x64, 0x20, 0x74, 0x65, 0x6C, 0x6C, 0x75,
          0x73, 0x2E>>

      assert decode!(data) == expected
    end

    test "binary" do
      expected = <<49, 50, 51, 52, 53, 54, 55, 56, 57>>
      assert decode!(<<0xC0, 9, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected
      assert decode!(<<0xC1, 9, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected
      assert decode!(<<0xC2, 9, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected
      assert decode!(<<0xC3, 9, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected
      assert decode!(<<0xC4, 9, 0, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected
      assert decode!(<<0xC5, 9, 0, 0, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) == expected

      assert decode!(<<0xC6, 9, 0, 0, 0, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) ==
               expected

      assert decode!(<<0xC7, 9, 0, 0, 0, 0, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 57>>) ==
               expected
    end

    test "array with index table" do
      expected = [1, 2, 3]
      assert decode!(<<0x06, 0x09, 0x03, 0x31, 0x32, 0x33, 0x03, 0x04, 0x05>>) == expected
      assert decode!(<<0x06, 0x0A, 0x03, 0x00, 0x31, 0x32, 0x33, 0x03, 0x04, 0x05>>) == expected

      assert decode!(
               <<0x07, 0x0E, 0x00, 0x03, 0x00, 0x31, 0x32, 0x33, 0x05, 0x00, 0x06, 0x00, 0x07,
                 0x00>>
             ) == expected

      assert decode!(
               <<0x08, 0x18, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x31, 0x32, 0x33, 0x09,
                 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00>>
             ) == expected

      assert decode!(
               <<0x09, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x31, 0x32, 0x33, 0x09,
                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00,
                 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00,
                 0x00, 0x00, 0x00, 0x00, 0x00>>
             ) == expected
    end

    test "array with index table with single element" do
      assert decode!(<<0x06, 0x05, 0x01, 0x31, 0x03>>) == [1]
    end

    test "array without index table" do
      expected = [1, 2, 3]
      assert decode!(<<0x02, 0x05, 0x31, 0x32, 0x33>>) == expected
      assert decode!(<<0x02, 0x06, 0x00, 0x31, 0x32, 0x33>>) == expected
      assert decode!(<<0x03, 0x06, 0x00, 0x31, 0x32, 0x33>>) == expected
      assert decode!(<<0x04, 0x08, 0x00, 0x00, 0x00, 0x31, 0x32, 0x33>>) == expected

      assert decode!(<<0x05, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x31, 0x32, 0x33>>) ==
               expected

      assert decode!(<<0x02, 0x0B, 0x1B, 00::little-unsigned-size(64)>>) == [0.0]

      assert decode!(<<0x02, 0x0B, 0x1C, 00::little-unsigned-size(64)>>) == [
               DateTime.from_unix!(0, :millisecond)
             ]
    end

    test "compact array" do
      assert decode!(<<0x13, 0x06, 0x31, 0x28, 0x10, 0x02>>) == [1, 16]
    end

    test "nested arrays" do
      expected = [[1, 2, 3], [1, 2, 3]]

      assert decode!(<<0x02, 0x0C, 0x02, 0x05, 0x31, 0x32, 0x33, 0x02, 0x05, 0x31, 0x32, 0x33>>) ==
               expected
    end

    test "array with nested compact array" do
      expected = [[1, 2, 3], [1, 2, 3]]

      assert decode!(
               <<0x02, 0x0E, 0x13, 0x06, 0x31, 0x32, 0x33, 0x03, 0x13, 0x06, 0x31, 0x32, 0x33,
                 0x03>>
             ) == expected
    end

    test "object with single string entry" do
      expected = %{"a" => "b"}
      assert decode!(<<0x0B, 0x08, 0x01, 0x41, 0x61, 0x41, 0x62, 0x03>>) == expected
    end

    test "compact object" do
      expected = %{"a" => 12, "b" => true, "c" => "xyz"}

      assert decode!(
               <<0x14, 0x10, 0x41, 0x61, 0x28, 0x0C, 0x41, 0x62, 0x1A, 0x41, 0x63, 0x43, 0x78,
                 0x79, 0x7A, 0x03>>
             ) == expected
    end

    test "array of objects" do
      expected = [
        %{"a" => 12, "b" => true, "c" => "xyz"},
        %{"a" => 12, "b" => true, "c" => "xyz"}
      ]

      assert decode!(
               <<0x13, 0x23, 0x14, 0x10, 0x41, 0x61, 0x28, 0x0C, 0x41, 0x62, 0x1A, 0x41, 0x63,
                 0x43, 0x78, 0x79, 0x7A, 0x03, 0x14, 0x10, 0x41, 0x61, 0x28, 0x0C, 0x41, 0x62,
                 0x1A, 0x41, 0x63, 0x43, 0x78, 0x79, 0x7A, 0x03, 0x02>>
             ) == expected
    end

    test "fixed size array of mix types" do
      expected = [
        %{"key" => 42},
        "fooooobar",
        "x",
        <<0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08>>
      ]

      data = <<
        0x02,
        0x2A,
        # object
        0x0B,
        0x0A,
        0x01,
        0x43,
        0x6B,
        0x65,
        0x79,
        0x28,
        0x2A,
        0x03,
        # string "fooooobar"
        0x49,
        0x66,
        0x6F,
        0x6F,
        0x6F,
        0x6F,
        0x6F,
        0x62,
        0x61,
        0x72,
        # string "x"
        0xBF,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x78,
        # binary data
        0xC0,
        0x08,
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08
      >>

      assert decode!(data) == expected
    end

    test "object 1 byte offset" do
      expected = %{
        "0" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "1" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "2" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "3" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "4" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"}
      }

      assert decode!(
               <<0x0B, 0xE9, 0x05, 0x41, 0x30, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x41, 0x31, 0x0B, 0x2B,
                 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11,
                 0x18, 0x1F, 0x41, 0x32, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x41, 0x33, 0x0B, 0x2B, 0x05,
                 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18,
                 0x1F, 0x41, 0x34, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x03, 0x30, 0x5D, 0x8A, 0xB7>>
             ) == expected
    end

    test "object 2 bytes offset" do
      expected = %{
        "0" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "1" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "2" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "3" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "4" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "5" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "6" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "7" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "8" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        },
        "9" => %{
          "0" => "test",
          "1" => "test",
          "2" => "test",
          "3" => "test",
          "4" => "test",
          "5" => "test",
          "6" => "test",
          "7" => "test",
          "8" => "test",
          "9" => "test"
        }
      }

      assert decode!(
               <<0x0C, 0x6F, 0x03, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x30, 0x0B, 0x53,
                 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D,
                 0x34, 0x3B, 0x42, 0x41, 0x31, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x32, 0x0B,
                 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26,
                 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x33, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x34,
                 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F,
                 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x35, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41,
                 0x36, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18,
                 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x37, 0x0B, 0x53, 0x0A, 0x41, 0x30,
                 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42,
                 0x41, 0x38, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
                 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11,
                 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x39, 0x0B, 0x53, 0x0A, 0x41,
                 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74,
                 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73,
                 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65,
                 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74,
                 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44,
                 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B,
                 0x42, 0x09, 0x00, 0x5E, 0x00, 0xB3, 0x00, 0x08, 0x01, 0x5D, 0x01, 0xB2, 0x01,
                 0x07, 0x02, 0x5C, 0x02, 0xB1, 0x02, 0x06, 0x03>>
             ) == expected
    end
  end
end
