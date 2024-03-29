defmodule VelocyPack.EncoderTest do
  use ExUnit.Case, async: true

  import VelocyPack

  describe "encode" do
    test "illegal" do
      assert encode!(:illegal) == <<0x17>>
    end

    test "nil" do
      assert encode!(nil) == <<0x18>>
    end

    test "boolean" do
      assert encode!(false) == <<0x19>>
      assert encode!(true) == <<0x1A>>
    end

    test "double" do
      assert encode!(133.7) == <<0x1B, 0x66, 0x66, 0x66, 0x66, 0x66, 0xB6, 0x60, 0x40>>
      assert encode!(-133.7) == <<0x1B, 0x66, 0x66, 0x66, 0x66, 0x66, 0xB6, 0x60, 0xC0>>
    end

    test "min/max key" do
      assert encode!(:min_key) == <<0x1E>>
      assert encode!(:max_key) == <<0x1F>>
    end

    test "small int" do
      assert encode!(0) == <<0x30>>
      assert encode!(1) == <<0x31>>
      assert encode!(2) == <<0x32>>
      assert encode!(3) == <<0x33>>
      assert encode!(4) == <<0x34>>
      assert encode!(5) == <<0x35>>
      assert encode!(6) == <<0x36>>
      assert encode!(7) == <<0x37>>
      assert encode!(8) == <<0x38>>
      assert encode!(9) == <<0x39>>
      assert encode!(-6) == <<0x3A>>
      assert encode!(-5) == <<0x3B>>
      assert encode!(-4) == <<0x3C>>
      assert encode!(-3) == <<0x3D>>
      assert encode!(-2) == <<0x3E>>
      assert encode!(-1) == <<0x3F>>
    end

    test "int" do
      assert encode!(-7) == <<0x20, -7::little-signed>>
      assert encode!(-128) == <<0x20, 0x80>>
      assert encode!(-32768) == <<0x21, 0x00, 0x80>>
      assert encode!(-8_388_608) == <<0x22, 0x00, 0x00, 0x80>>
      assert encode!(-2_147_483_648) == <<0x23, 0x00, 0x00, 0x00, 0x80>>
      assert encode!(-549_755_813_888) == <<0x24, 0x00, 0x00, 0x00, 0x00, 0x80>>
      assert encode!(-140_737_488_355_328) == <<0x25, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80>>

      assert encode!(-36_028_797_018_963_968) ==
               <<0x26, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80>>

      assert encode!(-9_223_372_036_854_775_808) ==
               <<0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80>>

      assert encode!(255) == <<0x28, 0xFF>>
      assert encode!(65535) == <<0x29, 0xFF, 0xFF>>
      assert encode!(16_777_215) == <<0x2A, 0xFF, 0xFF, 0xFF>>
      assert encode!(4_294_967_295) == <<0x2B, 0xFF, 0xFF, 0xFF, 0xFF>>
      assert encode!(1_099_511_627_775) == <<0x2C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>
      assert encode!(281_474_976_710_655) == <<0x2D, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>
      assert encode!(72_057_594_037_927_935) == <<0x2E, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>

      assert encode!(18_446_744_073_709_551_615) ==
               <<0x2F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>
    end

    test "short string" do
      assert encode!("Hallo Welt!") == <<0x4B, 72, 97, 108, 108, 111, 32, 87, 101, 108, 116, 33>>

      assert encode!("Hello World!") ==
               <<0x4C, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33>>
    end

    test "string" do
      data =
        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. " <>
          "Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. " <>
          "Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. " <>
          "Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, " <>
          "venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus. " <>
          "Vivamus elementum semper nisi. Aenean vulputate eleifend tellus."

      expected =
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

      assert encode!(data) == expected
    end

    test "empty list" do
      assert encode!([]) == <<0x01>>
    end

    test "lists with same sized elements as arrays without index table" do
      assert encode!([1, 2, 3]) == <<0x02, 0x5, "1", "2", "3">>
      v = for i <- -6..9, do: i
      <<0x02, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v

      v = for i <- 256..512, do: i
      <<0x03, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v

      v = for i <- 65537..131_072, do: i
      <<0x04, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v
    end

    test "lists with different sized elements as arrays with index table" do
      assert encode!([256, 1, 2]) ==
               <<0x06, 0x0B, 0x3, 0x29, 256::little-unsigned-size(16), "1", "2", 0x03, 0x06,
                 0x07>>

      v = for i <- 1..64, do: i
      <<0x06, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v

      v = for i <- 1..1024, do: i
      <<0x07, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v

      v = for i <- 1..65537, do: i
      <<0x08, _::binary>> = encoded = encode!(v)
      assert decode!(encoded) == v
    end

    test "list with single element of size 254" do
      # this tests the edge case where we cannot use a list where the total size is stored
      # as a single byte because the total size is actually datasize + 2
      list = [
        %{
          "nodeId" => "00000000-0000-0000-0000-000000000000",
          "nodeType" => "C",
          "operationType" => "V",
          "value" => %{
            "createdAt" => 1234567890123,
            "createdBy" => "00000000-0000-0000-0000-000000000000",
            "hidden" => true,
            "name" => "XXX",
            "state" => "XXXXXXXX",
            "updatedAt" => 1234567890123,
            "updatedBy" => "00000000-0000-0000-0000-000000000000"
          }
        }
      ]
      assert encode!(list) |> decode!(list) == list
    end

    test "compact array" do
      assert encode!([1, 16], compact_arrays: true) == <<0x13, 0x06, 0x31, 0x28, 0x10, 0x02>>

      # This test covers the corner case were, due to the number of bytes required for the size
      # information itself, an additional byte is needed to encode the final total size.
      s =
        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. " <>
          "Aenean massa. Cum sociis ..."

      v = [s, 1, 2, 42]
      <<0x13, _::binary>> = encoded = encode!(v, compact_arrays: true)
      assert decode!(encoded) == v
    end

    test "nested list" do
      expected = <<0x02, 0x0C, 0x02, 0x05, 0x31, 0x32, 0x33, 0x02, 0x05, 0x31, 0x32, 0x33>>
      data = [[1, 2, 3], [1, 2, 3]]
      assert encode!(data) == expected
    end

    test "empty object" do
      assert encode!(%{}) == <<0x0A>>
    end

    test "object with string and atom keys" do
      assert encode!(%{"a" => "b"}) == <<0x0B, 0x08, 0x01, 0x41, 0x61, 0x41, 0x62, 0x03>>

      assert encode!(%{a: "b", b: "a"}) ==
               <<0x0B, 0x0D, 0x02, 0x41, 0x61, 0x41, 0x62, 0x41, 0x62, 0x41, 0x61, 0x03, 0x07>>
    end

    test "object 1 byte offset" do
      data = %{
        "0" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "1" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "2" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "3" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"},
        "4" => %{"0" => "test", "1" => "test", "2" => "test", "3" => "test", "4" => "test"}
      }

      expected =
        <<0x0B, 0xE9, 0x05, 0x41, 0x30, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x41, 0x31, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x41, 0x32, 0x0B, 0x2B, 0x05,
          0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x41, 0x33,
          0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18,
          0x1F, 0x41, 0x34, 0x0B, 0x2B, 0x05, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03,
          0x0A, 0x11, 0x18, 0x1F, 0x03, 0x30, 0x5D, 0x8A, 0xB7>>

      assert encode!(data) == expected
    end

    test "object 2 bytes offset" do
      data = %{
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

      expected =
        <<0x0C, 0x6B, 0x03, 0x0A, 0x00, 0x41, 0x30, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18,
          0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x31, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11,
          0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x32, 0x0B, 0x53, 0x0A, 0x41, 0x30,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A,
          0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x33, 0x0B, 0x53, 0x0A, 0x41,
          0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41,
          0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74, 0x03,
          0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x34, 0x0B, 0x53, 0x0A,
          0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73, 0x74,
          0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x35, 0x0B, 0x53,
          0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65, 0x73,
          0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x36, 0x0B,
          0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74, 0x65,
          0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74, 0x65,
          0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74, 0x65,
          0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74, 0x65,
          0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74, 0x65,
          0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41, 0x37,
          0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44, 0x74,
          0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42, 0x41,
          0x38, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39, 0x44,
          0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B, 0x42,
          0x41, 0x39, 0x0B, 0x53, 0x0A, 0x41, 0x30, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x31,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x32, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x33,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x34, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x35,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x36, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x37,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x38, 0x44, 0x74, 0x65, 0x73, 0x74, 0x41, 0x39,
          0x44, 0x74, 0x65, 0x73, 0x74, 0x03, 0x0A, 0x11, 0x18, 0x1F, 0x26, 0x2D, 0x34, 0x3B,
          0x42, 0x05, 0x00, 0x5A, 0x00, 0xAF, 0x00, 0x04, 0x01, 0x59, 0x01, 0xAE, 0x01, 0x03,
          0x02, 0x58, 0x02, 0xAD, 0x02, 0x02, 0x03>>

      assert encode!(data) == expected
    end

    test "compact object" do
      data = %{"a" => 12, "b" => true, "c" => "xyz"}

      expected =
        <<0x14, 0x10, 0x41, 0x61, 0x28, 0x0C, 0x41, 0x62, 0x1A, 0x41, 0x63, 0x43, 0x78, 0x79,
          0x7A, 0x03>>

      assert encode!(data, compact_objects: true) == expected
    end
  end
end
