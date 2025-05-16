defmodule ArchethicClient.Crypto do
  @moduledoc """
  Provide cryptographic operations for Archethic network.
  """

  alias __MODULE__.ECDSA
  alias __MODULE__.Ed25519
  alias __MODULE__.ID
  alias ArchethicClient.Utils

  @typedoc """
  List of the supported hash algorithms
  """
  @type supported_hash :: :sha256 | :sha512 | :sha3_256 | :sha3_512 | :blake2b

  @typedoc """
  List of the supported elliptic curves
  """
  @type supported_curve :: :ed25519 | ECDSA.curve()

  @typedoc """
  List of the supported key origins
  """
  @type supported_origin :: :software | :tpm | :on_chain_wallet

  @typedoc """
  Binary representing a hash prepend by a single byte to identify the algorithm of the generated hash
  """
  @type versioned_hash :: <<_::8, _::_*8>>

  @typedoc """
  Binary representing an address
  - first byte to identify the curve type
  - second byte to identify hash algorithm of the generated hash
  """
  @type address :: <<_::16, _::_*8>>

  @typedoc """
  Hexadecimal reprensentation of type `address`
  """
  @type hex_address :: String.t()

  @type sha256 :: <<_::256>>

  @typedoc """
  Binary representing a key prepend by two bytes:
  - to identify the elliptic curve for a key
  - to identify the origin of the key derivation (software, TPM)
  """
  @type key :: <<_::16, _::_*8>>

  @typedoc """
  Binary representing a AES key on 32 bytes
  """
  @type aes_key :: <<_::256>>

  @typedoc """
  Binary representing an encrypted data using AES authenticated encryption.
  The binary is split following this rule:
  - 12 bytes for the IV (Initialization Vector)
  - 16 bytes for the Authentication tag
  - The rest for the ciphertext
  """
  @type aes_cipher :: <<_::384, _::_*8>>

  @typedoc """
  Options for derivation
  """
  @type derivation_options :: [curve: supported_curve(), origin: supported_origin(), hash_algo: supported_hash()]

  @doc """
  Derive a new keypair from a seed and an index representing the number of previous generate keypair.

  The seed generates a master key and an entropy used in the child keys generation.

                                                               / (256 bytes) Next private key
                          (256 bytes) Master key  --> HMAC-512
                        /                              Key: Master entropy,
      seed --> HASH-512                                Data: Master key + index)
                        \
                         (256 bytes) Master entropy



  ## Examples

      iex> {pub, _} = Crypto.derive_keypair("myseed", 1)
      ...> {pub10, _} = Crypto.derive_keypair("myseed", 10)
      ...> {pub_bis, _} = Crypto.derive_keypair("myseed", 1)
      ...> pub != pub10 and pub == pub_bis
      true

      iex> {pub, _} = Crypto.derive_keypair("myseed", 1, curve: :ed25519, origin: :on_chain_wallet)
      ...> <<curve_id::8, origin_id::8, _::binary>> = pub
      ...> origin_id == 0 and curve_id == 0
      true
  """
  @spec derive_keypair(seed :: binary(), index :: non_neg_integer(), opts :: derivation_options()) ::
          {public_key :: key(), private_key :: key()}
  def derive_keypair(seed, index, opts \\ []) when is_binary(seed) and is_integer(index) and is_list(opts),
    do: seed |> get_extended_seed(<<index::32>>) |> generate_deterministic_keypair(opts)

  @doc """
  Generate a keypair in a deterministic way using a seed

  ## Examples

      iex> {pub, _} = Crypto.generate_deterministic_keypair("myseed")
      ...> pub
      <<0, 1, 91, 43, 89, 132, 233, 51, 190, 190, 189, 73, 102, 74, 55, 126, 44, 117, 50, 36, 220,
        249, 242, 73, 105, 55, 83, 190, 3, 75, 113, 199, 247, 165>>

      iex> {pub, _} = Crypto.generate_deterministic_keypair("myseed", curve: :secp256r1)
      ...> pub
      <<1, 1, 4, 140, 235, 188, 198, 146, 160, 92, 132, 81, 177, 113, 230, 39, 220, 122, 112, 231,
        18, 90, 66, 156, 47, 54, 192, 141, 44, 45, 223, 115, 28, 30, 48, 105, 253, 171, 105, 87,
        148, 108, 150, 86, 128, 28, 102, 163, 51, 28, 57, 33, 133, 109, 49, 202, 92, 184, 138, 187,
        26, 123, 45, 5, 94, 180, 250>>
  """
  @spec generate_deterministic_keypair(seed :: binary(), opts :: derivation_options()) ::
          {public_key :: key(), private_key :: key()}
  def generate_deterministic_keypair(seed, opts \\ []) when is_binary(seed) and is_list(opts) do
    [curve: curve, origin: origin] = get_opts(opts, [:curve, :origin])
    do_generate_deterministic_keypair(curve, origin, seed)
  end

  defp do_generate_deterministic_keypair(:ed25519, origin, seed),
    do: seed |> Ed25519.generate_keypair() |> ID.prepend_keypair(:ed25519, origin)

  defp do_generate_deterministic_keypair(curve, origin, seed),
    do: curve |> ECDSA.generate_keypair(seed) |> ID.prepend_keypair(curve, origin)

  defp get_extended_seed(seed, additional_data) do
    <<master_key::binary-32, master_entropy::binary-32>> = :crypto.hash(:sha512, seed)

    <<extended_pv::binary-32, _::binary-32>> =
      :crypto.mac(:hmac, :sha512, master_entropy, <<master_key::binary, additional_data::binary>>)

    extended_pv
  end

  @doc """
  Sign data.

  The first byte of the private key identifies the curve and the signature algorithm to use

  ## Examples

      iex> {_pub, pv} = Crypto.generate_deterministic_keypair("myseed")
      ...> Crypto.sign("myfakedata", pv)
      <<220, 110, 7, 254, 119, 249, 124, 5, 24, 45, 224, 214, 60, 49, 223, 238, 47, 58, 91, 108, 33,
        18, 230, 144, 178, 191, 236, 235, 188, 32, 224, 129, 47, 18, 216, 220, 32, 82, 252, 20, 55,
        2, 204, 94, 73, 37, 44, 220, 33, 26, 44, 124, 20, 44, 255, 249, 77, 201, 97, 108, 213, 107,
        134, 9>>
  """
  @spec sign(data :: iodata(), private_key :: binary()) :: signature :: binary()
  def sign(data, <<curve_id::8, _::8, key::binary>> = _private_key) when is_bitstring(data) or is_list(data),
    do: curve_id |> ID.to_curve() |> do_sign(Utils.wrap_binary(data), key)

  defp do_sign(:ed25519, data, key), do: Ed25519.sign(key, data)
  defp do_sign(curve, data, key), do: ECDSA.sign(curve, key, data)

  @doc """
  Encrypts data using public key authenticated encryption (ECIES).

  Ephemeral and random ECDH key pair is generated which is used to generate shared
  secret with the given public key(transformed to ECDH public key).

  Based on this secret, KDF derive keys are used to create an authenticated symmetric encryption.

  ## Examples

      ```
      {pub, _} = Crypto.generate_deterministic_keypair("myseed")
      Crypto.ec_encrypt("myfakedata", pub)
      <<20, 95, 27, 87, 71, 195, 100, 164, 225, 201, 163, 220, 15, 111, 201, 224, 41,
      34, 143, 78, 201, 109, 157, 196, 108, 109, 155, 91, 239, 118, 23, 100, 161,
      195, 39, 117, 148, 223, 182, 23, 1, 197, 205, 93, 239, 19, 27, 248, 168, 107,
      40, 0, 68, 224, 177, 110, 180, 24>>
      ```
  """
  @spec ec_encrypt(message :: binary(), public_key :: key()) :: binary()
  def ec_encrypt(message, <<curve_id::8, _::8, public_key::binary>> = _public_key) when is_binary(message) do
    curve = ID.to_curve(curve_id)

    {ephemeral_public_key, ephemeral_private_key} = generate_ephemeral_encryption_keys(curve)

    # Derivate secret using ECDH with the given public key and the ephemeral private key
    shared_key =
      case curve do
        :ed25519 ->
          x25519_pk = Ed25519.convert_to_x25519_public_key(public_key)
          :crypto.compute_key(:ecdh, x25519_pk, ephemeral_private_key, :x25519)

        _ ->
          :crypto.compute_key(:ecdh, public_key, ephemeral_private_key, curve)
      end

    # Generate keys for the AES authenticated encryption
    {iv, aes_key} = derivate_secrets(shared_key)
    {cipher, tag} = aes_auth_encrypt(iv, aes_key, message)

    # Encode the cipher within the ephemeral public key, the authentication tag
    <<ephemeral_public_key::binary, tag::binary, cipher::binary>>
  end

  defp generate_ephemeral_encryption_keys(:ed25519), do: :crypto.generate_key(:ecdh, :x25519)
  defp generate_ephemeral_encryption_keys(curve), do: :crypto.generate_key(:ecdh, curve)

  defp derivate_secrets(dh_key) do
    pseudorandom_key = :crypto.hash(:sha256, dh_key)
    iv = binary_part(:crypto.mac(:hmac, :sha256, pseudorandom_key, "0"), 0, 32)
    aes_key = binary_part(:crypto.mac(:hmac, :sha256, iv, "1"), 0, 32)
    {iv, aes_key}
  end

  defp aes_auth_encrypt(iv, key, data), do: :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, data, "", true)

  defp aes_auth_decrypt(iv, key, cipher, tag),
    do: :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, cipher, "", tag, false)

  @doc """
  Decrypt a cipher using public key authenticated encryption (ECIES).

  A cipher contains a generated ephemeral random public key coupled with an authentication tag.

  Private key is transformed to ECDH to compute a shared secret with this random public key.

  Based on this secret, KDF derive keys are used to create an authenticated symmetric decryption.

  Before the decryption, the authentication will be checked to ensure the given private key
  has the right to decrypt this data.

  ## Examples

      iex> cipher =
      ...>   <<20, 95, 27, 87, 71, 195, 100, 164, 225, 201, 163, 220, 15, 111, 201, 224, 41, 34,
      ...>     143, 78, 201, 109, 157, 196, 108, 109, 155, 91, 239, 118, 23, 100, 161, 195, 39, 117,
      ...>     148, 223, 182, 23, 1, 197, 205, 93, 239, 19, 27, 248, 168, 107, 40, 0, 68, 224, 177,
      ...>     110, 180, 24>>
      ...>
      ...> {_pub, pv} = Crypto.generate_deterministic_keypair("myseed")
      ...> ArchethicClient.Crypto.ec_decrypt!(cipher, pv)
      "myfakedata"

  Invalid message to decrypt or key return an error:

      iex> cipher =
      ...>   <<20, 95, 27, 87, 71, 195, 100, 164, 225, 201, 163, 220, 15, 111, 201, 224, 41, 34,
      ...>     143, 78, 201, 109, 157, 196, 108, 109, 155, 91, 239, 118, 23, 100, 161, 195, 39, 117,
      ...>     148, 223, 182, 23, 1, 197, 205, 93, 239, 19, 27, 248, 168, 107, 40, 0, 68, 224, 177,
      ...>     110, 180, 24>>
      ...>
      ...> {_, pv} = Crypto.generate_deterministic_keypair("otherseed")
      ...> Crypto.ec_decrypt!(cipher, pv)
      ** (RuntimeError) Decryption failed
  """
  @spec ec_decrypt!(encoded_cipher :: binary(), private_key :: key()) :: binary()
  def ec_decrypt!(encoded_cipher, private_key) when is_binary(encoded_cipher) and is_binary(private_key) do
    case ec_decrypt(encoded_cipher, private_key) do
      {:error, :decryption_failed} -> raise "Decryption failed"
      {:ok, data} -> data
    end
  end

  @doc """

  ## Examples

      iex> cipher =
      ...>   <<20, 95, 27, 87, 71, 195, 100, 164, 225, 201, 163, 220, 15, 111, 201, 224, 41, 34,
      ...>     143, 78, 201, 109, 157, 196, 108, 109, 155, 91, 239, 118, 23, 100, 161, 195, 39, 117,
      ...>     148, 223, 182, 23, 1, 197, 205, 93, 239, 19, 27, 248, 168, 107, 40, 0, 68, 224, 177,
      ...>     110, 180, 24>>
      ...>
      ...> {_pub, pv} = Crypto.generate_deterministic_keypair("myseed")
      ...> {:ok, "myfakedata"} = Crypto.ec_decrypt(cipher, pv)

  Invalid message to decrypt return an error:

      iex> cipher =
      ...>   <<20, 95, 27, 87, 71, 195, 100, 164, 225, 201, 163, 220, 15, 111, 201, 224, 41, 34,
      ...>     143, 78, 201, 109, 157, 196, 108, 109, 155, 91, 239, 118, 23, 100, 161, 195, 39, 117,
      ...>     148, 223, 182, 23, 1, 197, 205, 93, 239, 19, 27, 248, 168, 107, 40, 0, 68, 224, 177,
      ...>     110, 180, 24>>
      ...>
      ...> {_, pv} = Crypto.generate_deterministic_keypair("otherseed")
      ...> Crypto.ec_decrypt(cipher, pv)
      {:error, :decryption_failed}
  """
  @spec ec_decrypt(cipher :: binary(), private_key :: key()) ::
          {:ok, binary()} | {:error, :decryption_failed}
  def ec_decrypt(encoded_cipher, <<curve_id::8, _::8, private_key::binary>> = _private_key)
      when is_binary(encoded_cipher) do
    key_size = key_size(curve_id)

    <<ephemeral_public_key::binary-size(key_size), tag::binary-16, cipher::binary>> =
      encoded_cipher

    # Derivate shared key using ECDH with the given ephermal public key and the private key
    shared_key =
      case ID.to_curve(curve_id) do
        :ed25519 ->
          x25519_sk = Ed25519.convert_to_x25519_private_key(private_key)
          :crypto.compute_key(:ecdh, ephemeral_public_key, x25519_sk, :x25519)

        curve ->
          :crypto.compute_key(:ecdh, ephemeral_public_key, private_key, curve)
      end

    # Generate keys for the AES authenticated decryption
    {iv, aes_key} = derivate_secrets(shared_key)

    case aes_auth_decrypt(iv, aes_key, cipher, tag) do
      :error -> {:error, :decryption_failed}
      data -> {:ok, data}
    end
  rescue
    _ -> {:error, :decryption_failed}
  end

  @doc """
  Encrypt a data using AES authenticated encryption.
  """
  @spec aes_encrypt(data :: iodata(), key :: iodata()) :: aes_cipher
  def aes_encrypt(data, <<key::binary-32>> = _key) when is_binary(data) do
    iv = :crypto.strong_rand_bytes(12)
    {cipher, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, data, "", true)
    <<iv::binary-size(12), tag::binary-size(16), cipher::binary>>
  end

  @doc """
  Decrypt a ciphertext using the AES authenticated decryption.

  ## Examples

      iex> key =
      ...>   <<234, 210, 202, 129, 91, 76, 68, 14, 17, 212, 197, 49, 66, 168, 52, 111, 176, 182,
      ...>     227, 156, 5, 32, 24, 105, 41, 152, 67, 191, 187, 209, 101, 36>>
      ...>
      ...> ciphertext = Crypto.aes_encrypt("sensitive data", key)
      ...> Crypto.aes_decrypt(ciphertext, key)
      {:ok, "sensitive data"}

  Return an error when the key is invalid

      iex> ciphertext = Crypto.aes_encrypt("sensitive data", :crypto.strong_rand_bytes(32))
      ...> Crypto.aes_decrypt(ciphertext, :crypto.strong_rand_bytes(32))
      {:error, :decryption_failed}

  """
  @spec aes_decrypt(_encoded_cipher :: aes_cipher, key :: binary) ::
          {:ok, term()} | {:error, :decryption_failed}
  def aes_decrypt(<<iv::binary-12, tag::binary-16, cipher::binary>> = _encoded_cipher, <<key::binary-32>>) do
    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, cipher, "", tag, false) do
      :error -> {:error, :decryption_failed}
      data -> {:ok, data}
    end
  end

  @doc """
  Decrypt a ciphertext using the AES authenticated decryption.

  ## Examples

      iex> key =
      ...>   <<234, 210, 202, 129, 91, 76, 68, 14, 17, 212, 197, 49, 66, 168, 52, 111, 176, 182,
      ...>     227, 156, 5, 32, 24, 105, 41, 152, 67, 191, 187, 209, 101, 36>>
      ...>
      ...> ciphertext = Crypto.aes_encrypt("sensitive data", key)
      ...> Crypto.aes_decrypt!(ciphertext, key)
      "sensitive data"

  Return an error when the key is invalid

      ```
      ciphertext = Crypto.aes_encrypt("sensitive data", :crypto.strong_rand_bytes(32))
      Crypto.aes_decrypt!(ciphertext, :crypto.strong_rand_bytes(32))
      ** (RuntimeError) Decryption failed
      ```

  """
  @spec aes_decrypt!(encoded_cipher :: aes_cipher, key :: binary) :: term()
  def aes_decrypt!(encoded_cipher, key) when is_binary(encoded_cipher) and is_binary(key) do
    case aes_decrypt(encoded_cipher, key) do
      {:ok, data} -> data
      {:error, :decryption_failed} -> raise "Decryption failed"
    end
  end

  @doc """
  Hash a data.

  A first-byte prepends each hash to indicate the algorithm used.

  ## Examples

      iex> Crypto.hash("myfakedata", :sha256)
      <<0, 78, 137, 232, 16, 150, 235, 9, 199, 74, 41, 189, 246, 110, 65, 252, 17, 139, 109, 23,
        172, 84, 114, 35, 202, 102, 41, 167, 23, 36, 230, 159, 35>>

      iex> Crypto.hash("myfakedata", :blake2b)
      <<4, 244, 16, 24, 144, 16, 67, 113, 164, 214, 115, 237, 113, 126, 130, 76, 128, 99, 78, 223,
        60, 179, 158, 62, 239, 245, 85, 4, 156, 10, 2, 94, 95, 19, 166, 170, 147, 140, 117, 1, 169,
        132, 113, 202, 217, 193, 56, 112, 193, 62, 134, 145, 233, 114, 41, 228, 164, 180, 225, 147,
        2, 33, 192, 42, 184>>

      iex> Crypto.hash("myfakedata", :sha3_256)
      <<2, 157, 219, 54, 234, 186, 251, 4, 122, 216, 105, 185, 228, 211, 94, 44, 94, 104, 147, 182,
        189, 45, 28, 219, 218, 236, 19, 66, 87, 121, 240, 249, 218>>
  """
  @spec hash(data :: iodata(), algo :: supported_hash()) :: versioned_hash()
  def hash(data, algo \\ default_hash()) when is_bitstring(data) or is_list(data),
    do: data |> Utils.wrap_binary() |> do_hash(algo) |> ID.prepend_hash(algo)

  defp do_hash(data, :sha256), do: :crypto.hash(:sha256, data)
  defp do_hash(data, :sha512), do: :crypto.hash(:sha512, data)
  defp do_hash(data, :sha3_256), do: :crypto.hash(:sha3_256, data)
  defp do_hash(data, :sha3_512), do: :crypto.hash(:sha3_512, data)
  defp do_hash(data, :blake2b), do: :crypto.hash(:blake2b, data)

  @doc """
  Generate an address as per Archethic specification

  The fist-byte representing the curve type second-byte representing hash algorithm used and rest is the hash of publicKey as per Archethic specifications .

  ## Examples

    iex> Crypto.derive_public_key_address(
    ...>   <<0, 0, 157, 113, 213, 254, 97, 210, 136, 32, 204, 38, 221, 110, 231, 27, 163, 73, 150,
    ...>     202, 185, 91, 170, 254, 165, 166, 45, 60, 50, 23, 27, 157, 72, 46>>
    ...> )
    <<0, 0, 237, 169, 64, 209, 51, 194, 0, 226, 46, 145, 26, 40, 146, 74, 122, 110, 128, 42, 139,
      127, 93, 18, 43, 122, 169, 201, 243, 117, 73, 18, 230, 168>>

    iex> Crypto.derive_public_key_address(
    ...>   <<1, 0, 4, 248, 44, 107, 181, 219, 4, 20, 188, 213, 46, 31, 29, 116, 140, 39, 108, 242,
    ...>     117, 190, 25, 128, 173, 250, 36, 119, 76, 23, 39, 168, 210, 107, 180, 174, 216, 221,
    ...>     151, 80, 232, 26, 8, 236, 107, 115, 135, 147, 42, 38, 86, 78, 197, 95, 163, 64, 214,
    ...>     91, 47, 62, 99, 103, 63, 150, 41, 25, 39>>,
    ...>   :blake2b
    ...> )
    <<1, 4, 26, 243, 32, 71, 95, 147, 6, 64, 254, 170, 221, 155, 83, 216, 75, 147, 255, 23, 33, 219,
      222, 211, 162, 67, 100, 63, 75, 101, 183, 247, 158, 80, 169, 78, 112, 131, 176, 191, 40, 87,
      45, 96, 181, 185, 74, 55, 85, 138, 240, 110, 164, 165, 219, 183, 138, 173, 188, 124, 125, 216,
      194, 106, 186, 204>>
  """
  @spec derive_public_key_address(public_key :: key(), algo :: supported_hash()) :: address()
  def derive_public_key_address(<<curve_type::8, _rest::binary>> = public_key, algo \\ default_hash()),
    do: public_key |> hash(algo) |> ID.prepend_curve(curve_type)

  @spec derive_address(seed :: binary(), index :: non_neg_integer(), opts :: derivation_options()) :: address()
  def derive_address(seed, index, opts \\ []) when is_binary(seed) and is_integer(index) and is_list(opts) do
    [hash_algo: hash_algo] = get_opts(opts, [:hash_algo])
    seed |> derive_keypair(index, opts) |> elem(0) |> derive_public_key_address(hash_algo)
  end

  defp key_size(0), do: 32
  defp key_size(1), do: 65
  defp key_size(2), do: 65

  @doc """
  Get the default elliptic curve
  """
  @spec default_curve() :: supported_curve()
  def default_curve,
    do: :archethic_client |> Application.get_env(__MODULE__, []) |> Keyword.get(:default_curve, :ed25519)

  @doc """
  Get the default elliptic curve
  """
  @spec default_hash() :: supported_hash()
  def default_hash, do: :archethic_client |> Application.get_env(__MODULE__, []) |> Keyword.get(:default_hash, :sha256)

  defp get_opts(opts, opts_key) do
    opts
    |> Keyword.validate!(curve: default_curve(), origin: :software, hash_algo: default_hash())
    |> Keyword.take(opts_key)
    |> Enum.sort()
  end

  @doc """
  Determine if a public key is valid
  """
  @spec valid_public_key?(binary()) :: boolean()
  def valid_public_key?(<<curve::8, _::8, public_key::binary>>) when curve in [0, 1, 2],
    do: byte_size(public_key) == key_size(curve)

  def valid_public_key?(_), do: false

  @doc """
  Determine if a hash is valid
  """
  @spec valid_hash?(binary()) :: boolean()
  def valid_hash?(<<0::8, _::binary-size(32)>>), do: true
  def valid_hash?(<<1::8, _::binary-size(64)>>), do: true
  def valid_hash?(<<2::8, _::binary-size(32)>>), do: true
  def valid_hash?(<<3::8, _::binary-size(64)>>), do: true
  def valid_hash?(<<4::8, _::binary-size(64)>>), do: true
  def valid_hash?(<<5::8, _::binary-size(32)>>), do: true
  def valid_hash?(_), do: false

  @doc """
  Determine if an address is valid
  """
  @spec valid_address?(binary()) :: boolean()
  def valid_address?(<<curve::8, rest::binary>>) when curve in [0, 1, 2], do: valid_hash?(rest)
  def valid_address?(_), do: false

  @doc """
  Verify a signature.

  The first byte of the public key identifies the curve and the verification algorithm to use.

  ## Examples

      iex> {pub, pv} = Crypto.generate_deterministic_keypair("myseed")
      ...> sig = Crypto.sign("myfakedata", pv)
      ...> Crypto.verify?(sig, "myfakedata", pub)
      true

      iex> {pub, _} = Crypto.generate_deterministic_keypair("myseed")
      ...> sig = :crypto.strong_rand_bytes(72)
      ...> Crypto.verify?(sig, "myfakedata", pub)
      false
  """
  @spec verify?(signature :: binary(), data :: iodata() | bitstring() | [bitstring], public_key :: key()) :: boolean()
  def verify?(sig, data, <<curve_id::8, _::8, key::binary>> = _public_key) when is_bitstring(data) or is_list(data) do
    curve_id |> ID.to_curve() |> do_verify?(key, Utils.wrap_binary(data), sig)
  end

  defp do_verify?(:ed25519, key, data, sig), do: Ed25519.verify?(key, data, sig)
  defp do_verify?(curve, key, data, sig), do: ECDSA.verify?(curve, key, data, sig)
end
