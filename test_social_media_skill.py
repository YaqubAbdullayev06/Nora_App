import unittest
from datetime import datetime, timedelta

from ai_agent import AgentConfig, SystemAgent


class SocialMediaSkillTests(unittest.TestCase):
    def test_supported_platforms_are_exposed(self):
        agent = SystemAgent()
        platforms = agent.social_media.list_supported_platforms()
        self.assertIn('x', platforms)
        self.assertIn('linkedin', platforms)

    def test_unapproved_platform_is_rejected(self):
        agent = SystemAgent()
        result = agent.social_media.connect_account('instagram', 'demo-account')
        self.assertFalse(result['success'])
        self.assertIn('not in allowlist', result['error'].lower())

    def test_post_requires_explicit_approval(self):
        agent = SystemAgent()
        result = agent.social_media.post_content(
            platform='x',
            account_id='demo-account',
            text='Hello from Nora',
        )
        self.assertFalse(result['success'])
        self.assertIn('approval', result['error'].lower())

    def test_oauth_authorization_url_is_generated(self):
        agent = SystemAgent()
        result = agent.social_media.start_oauth_flow('x', redirect_uri='http://localhost:8000/callback')
        self.assertTrue(result['success'])
        self.assertIn('oauth2', result['authorization_url'])
        self.assertIn('client_id', result['authorization_url'])
        self.assertIn('redirect_uri', result['authorization_url'])
        self.assertIn('state', result['authorization_url'])

    def test_device_settings_respect_configured_allowlist(self):
        config = AgentConfig(device_settings_allowlist=['brightness'])
        agent = SystemAgent(config)

        self.assertEqual(agent.device_settings.list_supported_settings(), ['brightness'])

        brightness = agent.device_settings.read_setting('brightness')
        self.assertTrue(brightness['success'])

        volume = agent.device_settings.read_setting('volume')
        self.assertFalse(volume['success'])
        self.assertIn('allowlist', volume['error'].lower())

    def test_focus_mode_blocks_social_media_during_scheduled_window(self):
        agent = SystemAgent()
        before_start = datetime(2026, 9, 7, 8, 59)
        active_time = datetime(2026, 9, 7, 9, 15)
        after_end = datetime(2026, 9, 7, 10, 1)

        scheduled = agent.focus_mode.schedule('09:00', 60, 'Study', now=before_start)
        self.assertTrue(scheduled['success'])
        self.assertFalse(agent.focus_mode.is_active(before_start))
        self.assertTrue(agent.focus_mode.is_active(active_time))

        agent.focus_mode.start_at = datetime.now() - timedelta(seconds=1)
        agent.focus_mode.end_at = datetime.now() + timedelta(seconds=1)

        blocked = agent.social_media.start_oauth_flow(
            'x', redirect_uri='http://localhost:8000/callback'
        )
        self.assertFalse(blocked['success'])
        self.assertIn('focus mode', blocked['error'].lower())

        self.assertFalse(agent.focus_mode.is_active(after_end))
        agent.focus_mode.end_at = datetime.now() - timedelta(seconds=1)
        available = agent.social_media.start_oauth_flow(
            'x', redirect_uri='http://localhost:8000/callback'
        )
        self.assertTrue(available['success'])


if __name__ == '__main__':
    unittest.main()
