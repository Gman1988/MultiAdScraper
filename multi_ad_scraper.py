import time
import os
import argparse
import json
import logging
import datetime
import threading
import uuid
from flask import Flask, render_template, request, jsonify, send_from_directory
from playwright.sync_api import sync_playwright
from waitress import serve

# Konfiguracja logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("ad_scraper.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("MultiAdScraper")

class MultiAdScraper:
    def __init__(self, config_path="config.json"):
        # Domyślna konfiguracja globalna
        self.global_config = {
            "server_port": 5000,
            "headless": True,
            "base_refresh_interval": 300,
            "base_output_folder": "ads_output"
        }
        
        # Lista ad unitów
        self.ad_units = []
        
        # Wczytaj konfigurację z pliku
        self.load_config(config_path)
        
        # Jeśli nie ma zdefiniowanych ad unitów, dodaj przykładowy
        if not self.ad_units:
            self.add_default_ad_unit()
        
        # Utworzenie folderów wyjściowych dla każdego ad unitu
        for unit in self.ad_units:
            os.makedirs(unit["output_folder"], exist_ok=True)
        
        # Słownik do przechowywania flag ręcznego odświeżania
        self.manual_refresh_flags = {unit["id"]: threading.Event() for unit in self.ad_units}
        
        # Uruchomione wątki
        self.threads = []
        
        # Flaga do zatrzymania skryptu
        self.stop_signal = threading.Event()
    
    def add_default_ad_unit(self):
        """Dodaje przykładowy ad unit do konfiguracji"""
        default_unit = {
            "id": str(uuid.uuid4()),
            "name": "Default Ad Unit",
            "ad_unit_path": "/6355419/Travel/Europe/France/Paris",
            "ad_unit_size": [300, 250],
            "refresh_interval": self.global_config["base_refresh_interval"],
            "output_folder": os.path.join(self.global_config["base_output_folder"], "default_unit"),
            "custom_targeting": {
                "location": "paris",
                "theme": "travel"
            },
            "last_ad_info": {
                "timestamp": None,
                "filename": None,
                "path": None
            }
        }
        self.ad_units.append(default_unit)
    
    def load_config(self, config_path):
        """Wczytuje konfigurację z pliku JSON"""
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    loaded_config = json.load(f)
                    
                    if "global_config" in loaded_config:
                        for key in loaded_config["global_config"]:
                            if key in self.global_config:
                                self.global_config[key] = loaded_config["global_config"][key]
                    
                    if "ad_units" in loaded_config:
                        self.ad_units = loaded_config["ad_units"]
                        
                        for unit in self.ad_units:
                            if "id" not in unit:
                                unit["id"] = str(uuid.uuid4())
                            if "last_ad_info" not in unit:
                                unit["last_ad_info"] = {
                                    "timestamp": None,
                                    "filename": None,
                                    "path": None
                                }
                            if "custom_targeting" not in unit:
                                unit["custom_targeting"] = {}
                
                logger.info(f"Wczytano konfigurację z {config_path}")
            else:
                self.save_config(config_path)
                logger.info(f"Utworzono domyślny plik konfiguracyjny {config_path}")
        except Exception as e:
            logger.error(f"Błąd wczytywania konfiguracji: {e}")
    
    def save_config(self, config_path="config.json"):
        """Zapisuje konfigurację do pliku JSON"""
        try:
            config_to_save = {
                "global_config": self.global_config,
                "ad_units": self.ad_units
            }
            
            with open(config_path, 'w') as f:
                json.dump(config_to_save, f, indent=4)
            logger.info(f"Zapisano konfigurację do {config_path}")
        except Exception as e:
            logger.error(f"Błąd zapisywania konfiguracji: {e}")
    
    def get_ad_unit_by_id(self, unit_id):
        """Znajduje ad unit po ID"""
        for unit in self.ad_units:
            if unit["id"] == unit_id:
                return unit
        return None
    
    def get_ad_page_html(self, ad_unit):
        """Generuje HTML strony z reklamą dla konkretnego ad unitu"""
        
        # Przygotuj kod JavaScript dla custom targeting
        targeting_js = ""
        if 'custom_targeting' in ad_unit and ad_unit['custom_targeting']:
            targeting_lines = []
            for key, value in ad_unit['custom_targeting'].items():
                if isinstance(value, list):
                    value_str = json.dumps(value)
                    targeting_lines.append(f'slot.setTargeting("{key}", {value_str});')
                else:
                    targeting_lines.append(f'slot.setTargeting("{key}", "{value}");')
            
            targeting_js = "\n                    ".join(targeting_lines)
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Google Ad Manager - {ad_unit["name"]}</title>
            <script async src="https://securepubads.g.doubleclick.net/tag/js/gpt.js"></script>
            <script>
                window.googletag = window.googletag || {{cmd: []}};
                googletag.cmd.push(function() {{
                    var slot = googletag.defineSlot('{ad_unit["ad_unit_path"]}', {ad_unit["ad_unit_size"]}, 'ad-container')
                        .addService(googletag.pubads());
                        
                    // Custom Targeting
                    {targeting_js}
                    
                    googletag.pubads().enableSingleRequest();
                    googletag.enableServices();
                }});
                
                function notifyAdLoaded() {{
                    const adContainer = document.getElementById('ad-container');
                    if (adContainer.innerHTML.trim() !== '') {{
                        document.body.setAttribute('data-ad-loaded', 'true');
                    }}
                }}
                
                googletag.cmd.push(function() {{
                    googletag.pubads().addEventListener('slotRenderEnded', function(event) {{
                        if (event.slot.getSlotElementId() === 'ad-container') {{
                            setTimeout(notifyAdLoaded, 1000);
                        }}
                    }});
                }});
            </script>
            <style>
                #ad-container {{
                    width: {ad_unit["ad_unit_size"][0]}px;
                    height: {ad_unit["ad_unit_size"][1]}px;
                    margin: 0 auto;
                    border: 1px solid #ccc;
                }}
                body {{
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background-color: #f0f0f0;
                }}
            </style>
        </head>
        <body>
            <div id="ad-container">
                <script>
                    googletag.cmd.push(function() {{
                        googletag.display('ad-container');
                    }});
                </script>
            </div>
        </body>
        </html>
        """
        return html
    
    def capture_ad(self, ad_unit):
        """Przechwytuje reklamę dla konkretnego ad unitu"""
        unit_id = ad_unit["id"]
        logger.info(f"Przechwytywanie reklamy dla ad unitu: {ad_unit['name']} (ID: {unit_id})")
        
        with sync_playwright() as p:
            try:
                browser = p.chromium.launch(headless=self.global_config["headless"])
                context = browser.new_context(viewport={"width": ad_unit["ad_unit_size"][0] + 100, "height": ad_unit["ad_unit_size"][1] + 100})
                page = context.new_page()
                
                page_content = self.get_ad_page_html(ad_unit)
                page.set_content(page_content)
                
                try:
                    page.wait_for_selector('body[data-ad-loaded="true"]', timeout=30000)
                    logger.info(f"Wykryto załadowanie reklamy dla {ad_unit['name']}")
                except Exception as e:
                    logger.warning(f"Timeout przy oczekiwaniu na reklamę dla {ad_unit['name']}: {e}")
                
                time.sleep(2)
                
                ad_container = page.locator('#ad-container')
                
                timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"ad_{unit_id}_{timestamp}.png"
                filepath = os.path.join(ad_unit["output_folder"], filename)
                
                ad_container.screenshot(path=filepath)
                logger.info(f"Zapisano reklamę dla {ad_unit['name']} do pliku: {filepath}")
                
                ad_unit["last_ad_info"] = {
                    "timestamp": timestamp,
                    "filename": filename,
                    "path": filepath
                }
                
                self.save_config()
                
                browser.close()
                return filepath
                
            except Exception as e:
                logger.error(f"Błąd podczas przechwytywania reklamy dla {ad_unit['name']}: {e}")
                return None
    
    def ad_refresh_loop(self, ad_unit):
        """Pętla odświeżania reklam dla pojedynczego ad unitu"""
        unit_id = ad_unit["id"]
        logger.info(f"Rozpoczynam pętlę odświeżania dla {ad_unit['name']} co {ad_unit['refresh_interval']} sekund")
        
        while not self.stop_signal.is_set():
            try:
                self.capture_ad(ad_unit)
                
                for _ in range(ad_unit["refresh_interval"]):
                    if self.stop_signal.is_set() or self.manual_refresh_flags[unit_id].is_set():
                        break
                    time.sleep(1)
                
                self.manual_refresh_flags[unit_id].clear()
                
            except Exception as e:
                logger.error(f"Błąd w pętli odświeżania dla {ad_unit['name']}: {e}")
                time.sleep(10)
    
    def trigger_manual_refresh(self, unit_id):
        """Wyzwala ręczne odświeżenie reklamy"""
        ad_unit = self.get_ad_unit_by_id(unit_id)
        if not ad_unit:
            return {"status": "error", "message": f"Nie znaleziono ad unitu o ID: {unit_id}"}
        
        logger.info(f"Wywołano ręczne odświeżenie reklamy dla {ad_unit['name']}")
        self.manual_refresh_flags[unit_id].set()
        return {"status": "success", "message": f"Zlecono ręczne odświeżenie reklamy dla {ad_unit['name']}"}
    
    def add_ad_unit(self, unit_data):
        """Dodaje nowy ad unit"""
        try:
            new_unit = {
                "id": str(uuid.uuid4()),
                "name": unit_data.get("name", "Nowy Ad Unit"),
                "ad_unit_path": unit_data.get("ad_unit_path", "/default/ad/unit"),
                "ad_unit_size": unit_data.get("ad_unit_size", [300, 250]),
                "refresh_interval": unit_data.get("refresh_interval", self.global_config["base_refresh_interval"]),
                "output_folder": unit_data.get("output_folder", os.path.join(self.global_config["base_output_folder"], f"unit_{len(self.ad_units) + 1}")),
                "custom_targeting": unit_data.get("custom_targeting", {}),
                "last_ad_info": {
                    "timestamp": None,
                    "filename": None,
                    "path": None
                }
            }
            
            os.makedirs(new_unit["output_folder"], exist_ok=True)
            self.ad_units.append(new_unit)
            self.manual_refresh_flags[new_unit["id"]] = threading.Event()
            self.save_config()
            self.start_ad_unit_thread(new_unit)
            
            return {"status": "success", "message": f"Dodano nowy ad unit: {new_unit['name']}", "unit_id": new_unit["id"]}
        except Exception as e:
            logger.error(f"Błąd podczas dodawania nowego ad unitu: {e}")
            return {"status": "error", "message": f"Nie udało się dodać ad unitu: {str(e)}"}
    
    def update_ad_unit(self, unit_id, unit_data):
        """Aktualizuje konfigurację ad unitu"""
        ad_unit = self.get_ad_unit_by_id(unit_id)
        if not ad_unit:
            return {"status": "error", "message": f"Nie znaleziono ad unitu o ID: {unit_id}"}
        
        try:
            for key, value in unit_data.items():
                if key in ["name", "ad_unit_path", "ad_unit_size", "refresh_interval", "output_folder", "custom_targeting"]:
                    ad_unit[key] = value
            
            os.makedirs(ad_unit["output_folder"], exist_ok=True)
            self.save_config()
            
            return {"status": "success", "message": f"Zaktualizowano ad unit: {ad_unit['name']}"}
        except Exception as e:
            logger.error(f"Błąd podczas aktualizacji ad unitu {unit_id}: {e}")
            return {"status": "error", "message": f"Nie udało się zaktualizować ad unitu: {str(e)}"}
    
    def delete_ad_unit(self, unit_id):
        """Usuwa ad unit"""
        ad_unit = self.get_ad_unit_by_id(unit_id)
        if not ad_unit:
            return {"status": "error", "message": f"Nie znaleziono ad unitu o ID: {unit_id}"}
        
        try:
            self.ad_units = [unit for unit in self.ad_units if unit["id"] != unit_id]
            
            if unit_id in self.manual_refresh_flags:
                del self.manual_refresh_flags[unit_id]
            
            self.save_config()
            
            return {"status": "success", "message": f"Usunięto ad unit: {ad_unit['name']}"}
        except Exception as e:
            logger.error(f"Błąd podczas usuwania ad unitu {unit_id}: {e}")
            return {"status": "error", "message": f"Nie udało się usunąć ad unitu: {str(e)}"}
    
    def start_web_server(self):
        """Uruchamia serwer Flask"""
        app = Flask(__name__)
        
        @app.route('/')
        def index():
            return render_template('index.html', global_config=self.global_config, ad_units=self.ad_units)
        
        @app.route('/ad_unit/<unit_id>')
        def ad_unit_page(unit_id):
            ad_unit = self.get_ad_unit_by_id(unit_id)
            if not ad_unit:
                return "Ad Unit not found", 404
            return self.get_ad_page_html(ad_unit)
        
        @app.route('/refresh/<unit_id>', methods=['POST'])
        def refresh(unit_id):
            return jsonify(self.trigger_manual_refresh(unit_id))
        
        @app.route('/refresh_all', methods=['POST'])
        def refresh_all():
            for unit_id in self.manual_refresh_flags:
                self.manual_refresh_flags[unit_id].set()
            return jsonify({"status": "success", "message": "Zlecono odświeżenie wszystkich ad unitów"})
        
        @app.route('/update_global_config', methods=['POST'])
        def update_global_config():
            try:
                new_config = request.json
                for key, value in new_config.items():
                    if key in self.global_config:
                        self.global_config[key] = value
                
                self.save_config()
                return jsonify({"status": "success", "message": "Konfiguracja globalna zaktualizowana"})
            except Exception as e:
                return jsonify({"status": "error", "message": str(e)})
        
        @app.route('/add_ad_unit', methods=['POST'])
        def add_ad_unit():
            try:
                return jsonify(self.add_ad_unit(request.json))
            except Exception as e:
                return jsonify({"status": "error", "message": str(e)})
        
        @app.route('/update_ad_unit/<unit_id>', methods=['POST'])
        def update_ad_unit(unit_id):
            try:
                return jsonify(self.update_ad_unit(unit_id, request.json))
            except Exception as e:
                return jsonify({"status": "error", "message": str(e)})
        
        @app.route('/delete_ad_unit/<unit_id>', methods=['POST'])
        def delete_ad_unit(unit_id):
            try:
                return jsonify(self.delete_ad_unit(unit_id))
            except Exception as e:
                return jsonify({"status": "error", "message": str(e)})
        
        @app.route('/get_ad_units')
        def get_ad_units():
            return jsonify(self.ad_units)
        
        @app.route('/get_ad_unit/<unit_id>')
        def get_ad_unit(unit_id):
            ad_unit = self.get_ad_unit_by_id(unit_id)
            if not ad_unit:
                return jsonify({"status": "error", "message": f"Nie znaleziono ad unitu o ID: {unit_id}"}), 404
            return jsonify(ad_unit)
        
        @app.route('/ads_output/<path:filename>')
        def ads_output(filename):
            return send_from_directory(self.global_config["base_output_folder"], filename)
        
        def run_server():
            logger.info(f"Uruchamiam serwer web na porcie {self.global_config['server_port']}")
            serve(app, host='0.0.0.0', port=self.global_config['server_port'])
        
        server_thread = threading.Thread(target=run_server)
        server_thread.daemon = True
        server_thread.start()
        self.threads.append(server_thread)
    
    def start_ad_unit_thread(self, ad_unit):
        """Uruchamia wątek odświeżania dla ad unitu"""
        thread = threading.Thread(target=self.ad_refresh_loop, args=(ad_unit,))
        thread.daemon = True
        thread.start()
        self.threads.append(thread)
        return thread
    
    def start(self):
        """Uruchamia cały system"""
        self.start_web_server()
        
        for ad_unit in self.ad_units:
            self.start_ad_unit_thread(ad_unit)
        
        logger.info("System uruchomiony. Naciśnij Ctrl+C, aby zatrzymać.")
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Otrzymano sygnał zatrzymania.")
            self.stop()
    
    def stop(self):
        """Zatrzymuje system"""
        logger.info("Zatrzymywanie systemu...")
        self.stop_signal.set()
        
        for thread in self.threads:
            if thread.is_alive():
                thread.join(timeout=5)
        
        logger.info("System zatrzymany.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MultiAdScraper - system do pobierania reklam z wielu ad unitów w Google Ad Manager")
    parser.add_argument("--config", default="config.json", help="Ścieżka do pliku konfiguracyjnego")
    args = parser.parse_args()
    
    scraper = MultiAdScraper(config_path=args.config)
    scraper.start()