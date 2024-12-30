# Tiny tapeout test code for kstep
import machine, ttboard

class test_kstep:
    def __init__(self, spirate=10000000):
        self.tt = tt = ttboard.demoboard.DemoBoard.get()
        # Setup SPI
        pin_miso = tt.pins.pin_uio2
        self.pin_cs = pin_cs = tt.pins.pin_uio0
        pin_sclk = tt.pins.pin_uio3
        pin_mosi = tt.pins.pin_uio1
        pin_miso.init(pin_miso.IN, pin_miso.PULL_UP)
        pin_cs.init(pin_cs.OUT)
        pin_sclk.init(pin_sclk.OUT)
        pin_mosi.init(pin_mosi.OUT)
        self.spi = machine.SoftSPI(
            baudrate=spirate, polarity=0, phase=0, bits=8,
            firstbit=machine.SPI.MSB,
            sck=pin_sclk, mosi=pin_mosi, miso=pin_miso)
    def set_pin_shutdown(self, val):
        self.tt.uio_in[5] = not not val
    def enable(self):
        tt = self.tt
        # Enable kstep
        tt.shuttle['tt_um_koconnor_kstep'].enable()
        tt.reset_project(True)
        # Setup uio pin directions (drive cs, mosi, clk, shutdown)
        tt.uio_oe_pico.value = 0b00101011
        # Make sure shutdown pin is low
        self.set_pin_shutdown(0)
        # Exit reset mode
        tt.reset_project(False)
    def read_reg(self, addr):
        is_write = 0
        v = [(is_write << 7) | (addr & 0x7f)]
        self.pin_cs(0)
        self.spi.write(bytearray(v))
        r = self.spi.read(4)
        self.pin_cs(1)
        return (r[0] << 24) | (r[1] << 16) | (r[2] << 8) | r[3]
    def write_reg(self, addr, val):
        is_write = 1
        v = [(is_write << 7) | (addr & 0x7f), (val >> 24) & 0xff,
             (val >> 16) & 0xff, (val >> 8) & 0xff, val & 0xff]
        self.pin_cs(0)
        self.spi.write(bytearray(v))
        self.pin_cs(1)
    def set_pulse_time(self, pulse_time):
        freq = float(self.tt.auto_clocking_freq)
        self.write_reg(0x12, max(0, min(0xffff, int(pulse_time * freq))))
    def set_next_step_dir(self, val):
        self.write_reg(0x22, not not val)
    def queue_steps(self, count, interval, add=0):
        # Wait for space in queue
        read_bidir_byte = ttboard.util.platform.read_bidir_byte
        while not read_bidir_byte() & 0x10:
            pass
        # Submit new entry
        self.write_reg(0x21, (interval & 0xffffffff))
        self.write_reg(0x20, ((count & 0xffff) << 16) | (add & 0xffff))
    def queue_steps_time(self, count, interval_time, add_time=0.0):
        freq = float(self.tt.auto_clocking_freq)
        self.queue_steps(count, int(interval_time * freq), int(add_time * freq))

# One can instantiate the above class with something like:
#kstep = test_kstep()
