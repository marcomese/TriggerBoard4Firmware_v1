library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

entity genericMUX is
generic(
    padding      : std_logic := '0';
    paddingLeft  : boolean   := false
);
port(
    dataIn  : in  std_logic_vector;
    dataOut : out std_logic_vector;
    dataSel : in  natural
);
end genericMUX;

architecture arch_genericMUX of genericMUX is

constant dInLen   : natural := dataIn'length;
constant dInLft   : natural := dataIn'left;
constant dOutLen  : natural := dataOut'length;
constant dOutLft  : natural := dataOut'left;

constant muxLen   : natural := natural(ceil(real(dInLen)/real(dOutLen)));

constant resBits  : natural := (muxLen*dOutLen)-dInLen;

type muxT is array(natural range 0 to muxLen-1) of std_logic_vector(dOutLen-1 downto 0);

signal muxOut : muxT;

begin

dataOut <= muxOut(muxLen-1-dataSel);

noPadding: if resBits = 0 generate
begin
    muxGEN: for i in muxOut'range generate
    begin
        muxOut(i) <= dataIn(dOutLft+(i*dOutLen) downto i*dOutLen);
    end generate;
end generate;

padLeft: if resBits /= 0 and paddingLeft generate
    constant padding : std_logic_vector(resBits-1 downto 0) := (others => padding);
begin
    muxOut(muxLen-1) <= padding & dataIn(dInLft downto dInLft-resBits+1);

    muxGEN: for i in 0 to muxLen-2 generate
    begin
        muxOut(i) <= dataIn(dOutLft+(i*dOutLen) downto i*dOutLen);
    end generate;
end generate;

padRight: if resBits /= 0 and not paddingLeft generate
    constant padding : std_logic_vector(resBits-1 downto 0) := (others => padding);
begin
    muxOut(0) <= dataIn(dOutLen-1-resBits downto 0) & padding;

    muxGEN: for i in 1 to muxLen-2 generate
    begin
        muxOut(i) <= dataIn(((i+1)*dOutLen)-1-resBits downto (i*dOutLen)-resBits);
    end generate;

    muxOut(muxLen-1) <= dataIn(dInLft downto ((muxLen-1)*dOutLen)-resBits);

end generate;

end architecture;